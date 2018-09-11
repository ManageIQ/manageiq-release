module ManageIQ
  module Release
    module SprintMilestone
      def self.all(repo, options = {})
        ManageIQ::Release.github.list_milestones(repo, options).select { |m| m.title =~ /^Sprint \d+/ }
      end

      def self.due_date_from_title(title)
        date = title.split(" Ending ").last.strip
        ActiveSupport::TimeZone.new('Pacific Time (US & Canada)').parse(date) # LOL GitHub, TimeZones are hard
      end
    end
  end
end
