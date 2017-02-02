require 'active_support/core_ext/time/calculations'
require 'active_support/values/time_zone'

module ManageIQ
  module Release
    class UpdateSprintMilestones
      attr_reader :repo, :title, :dry_run

      def initialize(repo, title, options = {})
        @repo = repo
        @title = title
        @dry_run = options[:dry_run]

        raise "Invalid title #{title.inspect}" unless title_valid?
      end

      def due_date
        date = title.split(" Ending ").last.strip
        ActiveSupport::TimeZone.new('Pacific Time (US & Canada)').parse(date) # LOL GitHub TimeZones are hard
      end

      def run
        other_sprint_milestones.each { |m| close(m) }
        create unless sprint_milestone
      end

      private

      def title_valid?
        title.include?(" Ending ")
      end

      def partitioned_sprint_milestones
        @partitioned_sprint_milestones ||= begin
          current, other = sprint_milestones.partition { |m| m.title == title }
          [current.first, other]
        end
      end

      def sprint_milestone
        partitioned_sprint_milestones.first
      end

      def other_sprint_milestones
        partitioned_sprint_milestones.last
      end

      def sprint_milestones
        github.list_milestones(repo).select { |m| m.title =~ /^Sprint \d+/ }
      end

      def create
        puts "Creating #{title.inspect}"

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
