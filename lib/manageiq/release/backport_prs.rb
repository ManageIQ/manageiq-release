module ManageIQ
  module Release
    class BackportPrs
      def self.search(branch, repo_names)
        query = repo_names.map { |r| "repo:#{r}" }.join(" ")
        query << " is:merged label:#{branch}/yes"

        ManageIQ::Release
          .github
          .search_issues(query)["items"]
          .sort_by(&:closed_at)
          .group_by { |pr| pr.repository_url.split("/").last(2).join("/") }
      end

      attr_reader :repo, :branch, :prs, :dry_run

      def initialize(repo, branch:, prs:, dry_run: false, **_)
        StringFormatting.enable

        @repo    = repo
        @branch  = branch
        @prs     = prs
        @dry_run = dry_run
      end

      def run
        repo.checkout(branch)
        repo.fetch
        backport_prs
      end

      private

      def backport_prs
        prs.each do |pr|
          puts
          puts "** #{github_repo}##{pr.number}".cyan
          puts

          success = backport_pr(pr.number, pr.user.login)
          puts

          if success
            repo.git.log("-1")
            puts
          else
            puts "A conflict occurred during backport. Stopping backports for #{github_repo}.".red
            break
          end
        end
        puts
      end

      def backport_pr(pr_number, pr_author)
        if cherry_pick(merge_commit_sha(pr_number))
          push_backport_commit

          add_comment(pr_number, <<~BODY)
            Backported to `#{branch}` in commit #{backport_commit_sha}.

            ```text
            #{backport_commit_log}
            ```
          BODY

          remove_label(pr_number, "#{branch}/yes")
          add_label(pr_number, "#{branch}/backported")

          true
        else
          add_comment(pr_number, <<~BODY)
            @#{pr_author} A conflict occurred during the backport of this pull request to `#{branch}`.

            If this pull request is based on another pull request that has not been \
            marked for backport, add the appropriate labels to the other pull request. \
            Otherwise, please create a new pull request direct to the `#{branch}` branch \
            in order to resolve this.
          BODY

          remove_label(pr_number, "#{branch}/yes")
          add_label(pr_number, "#{branch}/conflict")

          false
        end
      end

      def merge_commit_sha(pr_number)
        github.pull_request(github_repo, pr_number).merge_commit_sha
      end

      def backport_commit_sha
        repo.git.capturing.rev_parse("HEAD").chomp
      end

      def backport_commit_log
        repo.git.capturing.log("-1").chomp
      end

      def cherry_pick(sha)
        repo.git.cherry_pick("-m1", "-x", sha)
        true
      rescue MiniGit::GitError
        repo.git.cherry_pick("--abort")
        false
      end

      def push_backport_commit
        remote = "origin"
        if dry_run
          puts "** dry_run: repo.git.push(#{remote.inspect}, #{branch.inspect})".magenta
        else
          repo.git.push(remote, branch)
        end
      end

      def add_comment(pr_number, body)
        if dry_run
          puts "** dry_run: github.add_comment(#{github_repo.inspect}, #{pr_number.inspect}, #{body.pretty_inspect})".magenta
        else
          github.add_comment(github_repo, pr_number, body)
        end
      end

      def remove_label(pr_number, label)
        if dry_run
          puts "** dry_run: github.remove_label(#{github_repo.inspect}, #{pr_number.inspect}, #{label.inspect})".magenta
        else
          github.remove_label(github_repo, pr_number, label)
        end
      end

      def add_label(pr_number, label)
        label = [label]
        if dry_run
          puts "** dry_run: github.add_labels_to_an_issue(#{github_repo.inspect}, #{pr_number.inspect}, #{label.inspect})".magenta
        else
          github.add_labels_to_an_issue(github_repo, pr_number, label)
        end
      end

      def github_repo
        repo.github_repo
      end

      def github
        ManageIQ::Release.github
      end
    end
  end
end
