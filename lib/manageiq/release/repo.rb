require 'minigit'
require 'ostruct'

module ManageIQ
  module Release
    class Repo
      attr_reader :name, :options, :path

      def initialize(name, options = nil)
        @name = name
        @options = OpenStruct.new(options || {})
        @path = REPOS_DIR.join(name)
      end

      def github_repo
        [options.org || "ManageIQ", name].join("/")
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

      private

      def git_clone
        clone_source = options.clone_source || "git@github.com:#{github_repo}.git"
        exit($CHILD_STATUS.exitstatus) unless system("git clone #{clone_source} #{path}")
      end
    end
  end
end
