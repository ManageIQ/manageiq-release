require 'pathname'

module ManageIQ
  module Release
    class PullRequestBlasterOuter
      attr_reader :repo, :base, :head, :script, :dry_run, :message, :title

      ROOT_DIR = Pathname.new(__dir__).join("..", "..", "..").freeze
      def initialize(repo, base:, head:, script:, dry_run:, message:, title: nil, **_)
        @repo    = repo
        @base    = base
        @head    = head
        @script  = begin
          s = Pathname.new(script)
          s = ROOT_DIR.join(script) if s.relative?
          raise "File not found #{s}" unless File.exist?(s)
          s.to_s
        end
        @dry_run = dry_run
        @message = message
        @title   = (title || message)[0, 72]
      end

      def blast
        puts "+++ blasting #{repo.github_repo}..."

        repo.git
        repo.fetch(output: false)

        unless repo.remote_branch?("origin", base)
          puts "!!! Skipping #{repo.github_repo}: 'origin/#{base}' not found"
          return
        end

        repo.checkout(head, "origin/#{base}")
        run_script

        result = false
        if !commit_changes
          puts "!!! Failed to commit changes. Perhaps the script is wrong or #{repo.github_repo} is already updated."
        elsif dry_run
          result = "Committed but is dry run"
        else
          puts "Do you want to open a pull request on #{repo.github_repo} with the above changes? (Y/N)"
          answer = $stdin.gets.chomp
          if answer.upcase.start_with?("Y")
            fork_repo unless forked?
            push_branch
            result = open_pull_request
          end
        end
        puts "--- blasting #{repo.github_repo} complete"
        result
      end

      private

      def github
        ManageIQ::Release.github
      end

      def forked?
        github.repos(github.login).any? { |m| m.name == repo.name }
      end

      def fork_repo
        github.fork(repo.github_repo)
        until forked?
          print "."
          sleep 3
        end
      end

      def run_script
        repo.chdir do
          parts = []
          parts << "GITHUB_REPO=#{repo.github_repo}"
          parts << "DRY_RUN=true" if dry_run
          parts << script
          cmd = parts.join(" ")

          unless system(cmd)
            puts "!!! Script execution failed."
            exit $?.exitstatus
          end
        end
      end

      def commit_changes
        repo.chdir do
          begin
            repo.git.add("-v", ".")
            repo.git.commit("-m", message)
            repo.git.show
            if dry_run
              puts "!!! --dry-run enabled: If the above commit in #{repo.path} looks good, run again without dry run to fork the repo, push the branch and open a pull request."
            end
            true
          rescue MiniGit::GitError => e
            e.status.exitstatus == 0
          end
        end
      end

      def origin_remote
        "pr_blaster_outer"
      end

      def origin_url
        "git@github.com:#{github.login}/#{repo.name}.git"
      end

      def pr_head
        "#{github.login}:#{head}"
      end

      def push_branch
        repo.chdir do
          repo.git.remote("add", origin_remote, origin_url) unless repo.remote?(origin_remote)
          repo.git.push("-f", origin_remote, "#{head}:#{head}")
        end
      end

      def open_pull_request
        pr = github.create_pull_request(repo.github_repo, base, pr_head, title, title)
        pr.html_url
      rescue => err
        raise unless err.message.include?("A pull request already exists")
        puts "!!! Skipping.  #{err.message}"
      end
    end
  end
end
