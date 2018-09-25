module ManageIQ
  module Release
    class DeleteSprintMilestones
      attr_reader :repo, :title, :dry_run

      def initialize(repo, title:, dry_run: false)
        @repo    = repo
        @title   = title
        @dry_run = dry_run
      end

      def run
        delete
      end

      private

      def milestone
        @milestone ||= SprintMilestone.all(repo, :state => :all).detect { |m| m.title == title }
      end

      def delete
        if milestone.nil?
          puts "Skipping deleting #{title.inspect} because it doesn't exist"
          return
        end

        puts "Deleting #{title.inspect}"

        if dry_run
          puts "** dry-run: github.delete_milestone(#{repo.inspect}, #{milestone.number.inspect})"
        else
          github.delete_milestone(repo, milestone.number)
        end
      end

      def github
        ManageIQ::Release.github
      end
    end
  end
end
