module ManageIQ
  module Release
    class ReleaseMilestone
      attr_reader :repo, :title, :dry_run

      def initialize(repo, title:, dry_run:)
        @repo    = repo
        @title   = title
        @dry_run = dry_run
      end

      def run
        return if repo.options.has_real_releases
        return if github.list_milestones(github_repo).any? { |m| m.title.casecmp?(title) }
        create_milestone
      end

      private

      def create_milestone
        puts "Creating milestone #{title.inspect}"

        if dry_run
          puts "** dry-run: github.create_milestone(#{github_repo.inspect}, #{title.inspect})"
        else
          github.create_milestone(github_repo, title)
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
