module ManageIQ
  module Release
    class UpdateBranchProtection
      attr_reader :repo, :branch, :dry_run

      def initialize(repo, branch:, dry_run: false, **_)
        @repo    = repo
        @branch  = branch
        @dry_run = dry_run
      end

      def run
        protect_branch
      end

      private

      def protect_branch
        puts "Protecting #{branch} branch"

        settings = {
          :enforce_admins                => nil,
          :required_status_checks        => nil,
          :required_pull_request_reviews => nil,
          :restrictions                  => nil
        }

        if dry_run
          puts "** dry-run: github.protect_branch(#{repo.inspect}, #{branch.inspect}, #{settings.inspect[1..-2]})"
        else
          github.protect_branch(repo, branch, settings)
        end
      end

      def github
        ManageIQ::Release.github
      end
    end
  end
end
