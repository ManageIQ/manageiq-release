module ManageIQ
  module Release
    class UpdateRepoSettings
      attr_reader :repo, :dry_run

      def initialize(repo, dry_run: false)
        @repo    = repo
        @dry_run = dry_run
      end

      def run
        edit_repository
      end

      private

      def edit_repository
        puts "Editing #{repo}"

        settings = {
          :has_wiki           => false,
          :has_projects       => false,
          :allow_merge_commit => true,
          :allow_rebase_merge => false,
          :allow_squash_merge => false,
        }

        if dry_run
          puts "** dry-run: github.edit_repository(#{repo.inspect}, #{settings.inspect[1..-2]})"
        else
          github.edit_repository(repo, settings)
        end
      end

      def github
        ManageIQ::Release.github
      end
    end
  end
end
