require 'minigit'
require 'ostruct'

module ManageIQ
  module Release
    class Repo
      attr_reader :name, :options, :path

      def initialize(name, options = nil)
        @name    = name
        @options = OpenStruct.new(options || {})
        @path    = REPOS_DIR.join(github_repo)
      end

      def github_repo
        if name.include?("/")
          name
        else
          [options.org || "ManageIQ", name].join("/")
        end
      end

      def git
        @git ||= begin
          retried = false
          MiniGit.debug = true if ENV["GIT_DEBUG"]
          MiniGit.new(path)
        end
      rescue ArgumentError => err
        raise if retried
        raise unless err.message.include?("does not seem to exist")

        git_clone
        retried = true
        retry
      end

      def fetch(output: true)
        if output
          git.fetch(:all => true, :tags => true)
        else
          git.capturing.fetch(:all => true, :tags => true)
        end
      end

      def checkout(branch, source = "origin/#{branch}")
        git.reset(:hard => true)
        git.checkout("-B", branch, source)
      end

      def branch?(branch)
        git.rev_parse("--verify", branch)
        true
      rescue MiniGit::GitError
        false
      end

      def remote?(remote)
        begin
          git.remote("show", remote)
        rescue MiniGit::GitError => e
          false
        else
          true
        end
      end

      def remote_branch?(remote, branch)
        git.capturing.ls_remote(remote, branch).present?
      end

      def write_file(file, content, dry_run: false, **kwargs)
        if dry_run
          puts "** dry-run: Writing #{path.join(file).expand_path}"
        else
          File.write(file, content, kwargs.merge(:chdir => path))
        end
      end

      def rm_file(file, dry_run: false)
        return unless File.exist?(path.join(file))
        if dry_run
          puts "** dry-run: Removing #{path.join(file).expand_path}"
        else
          Dir.chdir(path) { FileUtils.rm_f(file) }
        end
      end

      def detect_readme_file
        Dir.chdir(path) do
          %w[README.md README README.txt].detect do |f|
            File.exist?(f)
          end
        end
      end

      private

      def git_clone
        clone_source = options.clone_source || "git@github.com:#{github_repo}.git"
        exit($CHILD_STATUS.exitstatus) unless system("git clone #{clone_source} #{path}")
      end
    end
  end
end
