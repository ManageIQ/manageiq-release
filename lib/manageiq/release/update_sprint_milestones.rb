require 'active_support/core_ext/time/calculations'
require 'active_support/values/time_zone'

module ManageIQ
  module Release
    class UpdateSprintMilestones
      attr_reader :repo, :title, :dry_run

      def initialize(repo, title:, dry_run: false)
        @repo    = repo
        @title   = title
        @dry_run = dry_run

        raise "Invalid title #{title.inspect}" unless SprintMilestone.valid_title?(title)
      end

      def run
        other_sprint_milestones.each { |m| close(m) }
        create unless sprint_milestone
      end

      private

      def partitioned_sprint_milestones
        @partitioned_sprint_milestones ||= begin
          current, other = SprintMilestone.all(repo).partition { |m| m.title == title }
          [current.first, other]
        end
      end

      def sprint_milestone
        partitioned_sprint_milestones.first
      end

      def other_sprint_milestones
        partitioned_sprint_milestones.last
      end

      def create
        puts "Creating #{title.inspect}"

        due_date = SprintMilestone.due_date_from_title(title)

        if dry_run
          puts "** dry-run: github.create_milestone(#{repo.inspect}, #{title.inspect}, :due_on => #{due_date.inspect})"
        else
          github.create_milestone(repo, title, :due_on => due_date)
        end
      end

      def close(milestone)
        puts "Closing #{milestone.title.inspect}"

        if dry_run
          puts "** dry-run: github.update_milestone(#{repo.inspect}, #{milestone.number.inspect}, :state => :closed) # title: #{milestone.title.inspect}"
        else
          github.update_milestone(repo, milestone.number, :state => :closed)
        end
      end

      def github
        ManageIQ::Release.github
      end
    end
  end
end
