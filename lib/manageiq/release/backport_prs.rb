module ManageIQ
  module Release
    class BackportPrs
      def self.search(repo_names, backport_labels)
        query = "is:merged "
        query << repo_names.map { |r| "repo:#{r}" }.join(" ")
        Array(backport_labels).each do |l|
          query << " label:#{l}"
        end

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
        repo.fetch
        repo.checkout(branch)
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
        success, failure_diff = cherry_pick(merge_commit_sha(pr_number))

        if success
          message = <<~BODY
            Backported to `#{branch}` in commit #{backport_commit_sha}.

            ```text
            #{backport_commit_log}
            ```
          BODY

          push_backport_commit
          add_comment(pr_number, message)
          remove_label(pr_number, "#{branch}/yes")
          add_label(pr_number, "#{branch}/backported")

          true
        else
          message = <<~BODY
            @#{pr_author} A conflict occurred during the backport of this pull request to `#{branch}`.

            If this pull request is based on another pull request that has not been \
            marked for backport, add the appropriate labels to the other pull request. \
            Otherwise, please create a new pull request direct to the `#{branch}` branch \
            in order to resolve this.

            Conflict details:

            ```diff
            #{failure_diff}
            ```
          BODY
          message = "#{message[0, 65_530]}\n```\n" if message.size > 65_535

          add_comment(pr_number, message)
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
        return true, nil
      rescue MiniGit::GitError
        diff = repo.git.capturing.diff.chomp
        repo.git.cherry_pick("--abort")
        return false, diff
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
