require "active_support/core_ext/time"

module ManageIQ
  module Release
    class ReleaseMilestone
      def self.valid_date?(date)
        !!parse_date(date)
      end

      def self.parse_date(date)
        ActiveSupport::TimeZone.new('Pacific Time (US & Canada)').parse(date) # LOL GitHub, TimeZones are hard
      end

      attr_reader :repo, :title, :due_on, :dry_run

      def initialize(repo, title:, due_on:, dry_run:)
        @repo    = repo
        @title   = title
        @due_on  = self.class.parse_date(due_on)
        @dry_run = dry_run
      end

      def run
        return if repo.options.has_real_releases

        existing = github.list_milestones(github_repo, :state => :all).detect { |m| m.title.casecmp?(title) }
        if existing
          update_milestone(existing)
        else
          create_milestone
        end
      end

      private

      def due_on_str
        due_on.strftime("%Y-%m-%d")
      end

      def update_milestone(existing)
        milestone_number = existing.number
        puts "Updating milestone #{title.inspect} (#{milestone_number}) with due date #{due_on_str.inspect}"

        if dry_run
          puts "** dry-run: github.update_milestone(#{github_repo.inspect}, #{milestone_number}, :due_on => #{due_on_str.inspect})"
        else
          github.update_milestone(github_repo, milestone_number, :due_on => due_on)
        end
      end

      def create_milestone
        puts "Creating milestone #{title.inspect} with due date #{due_on_str.inspect}"

        if dry_run
          puts "** dry-run: github.create_milestone(#{github_repo.inspect}, #{title.inspect}, :due_on => #{due_on_str.inspect})"
        else
          github.create_milestone(github_repo, title, :due_on => due_on)
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
