require 'pathname'

module ManageIQ
  module Release
    class PullRequestBlasterOuter
      attr_reader :repo, :branch, :script, :dry_run, :message
      def initialize(repo, branch:, script:, dry_run:, message:)
        @repo    = repo
        @branch  = branch
        @script  = begin
          s = Pathname.new(script)
          s = Pathname.new(__dir__).join("..", "..", "..", script) if s.relative?
          raise "File not found #{s}" unless File.exist?(s)
          s.to_s
        end
        @dry_run = dry_run
        @message = message
      end

      def blast
        puts "+++ blasting #{repo.github_repo}..."

        repo.git
        repo.fetch
        repo.checkout(pr_branch, "origin/#{branch}")

        run_script

        if !commit_changes
          puts "!!! Failed to commit changes. Perhaps the script is wrong or #{repo.github_repo} is already updated."
        elsif !dry_run
          fork_repo unless forked?
          push_branch
          open_pull_request
        end
        puts "--- blasting #{repo.github_repo} complete"
      end

      private

      def github
        ManageIQ::Release.github
      end

      def forked?
        github.repos(github.login).any? { |m| m.name == repo.name }
      end

      def with_status
        calling_method = caller_locations(1,1)[0].label
        puts "+++ #{calling_method}..."
        result = yield
        puts "--- #{calling_method}: #{result}"
        result
      end

      def fork_repo
        with_status do
          github.fork(repo.github_repo)
          until forked?
            print "."
            sleep 3
          end
        end
      end

      def run_script
        with_status do
          Dir.chdir(repo.path) do
            `#{script}`
          end
        end
      end

      def commit_changes
        with_status do
          Dir.chdir(repo.path) do
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
      end

      def origin_remote
        "pr_blaster_outer"
      end

      def origin_url
        "git@github.com:#{github.login}/#{repo.name}.git"
      end

      def pr_branch
        "pr_blaster_outer"
      end

      def pr_base
        "#{github.login}:#{pr_branch}"
      end

      def push_branch
        with_status do
          Dir.chdir(repo.path) do
            repo.git.remote("add", origin_remote, origin_url)
            repo.git.push("-f", origin_remote, "#{pr_branch}:#{pr_branch}")
          end
        end
      end

      def open_pull_request
        with_status do
          pr = github.create_pull_request(repo.github_repo, branch, pr_base, message[0,72], message[0,72])
          pr.html_url
        end
      end
    end
  end
end
