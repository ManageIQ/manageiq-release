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

      def self.valid_title?(title)
        title =~ /\ASprint \d+ Ending (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) \d+, 20\d\d\Z/
      end

      def self.next_title
        build_title(*sprints.first)
      end

      def self.build_title(number, date)
        "Sprint #{number} Ending #{date.strftime("%b %-d, %Y")}"
      end

      def self.sprints(as_of: Date.today)
        require "active_support/core_ext/numeric/time"
        # The first date when we started doing this cadence
        number = 76
        date   = Date.parse("Jan 1, 2018")

        Enumerator.new do |y|
          loop do
            y << [number, date] if date >= as_of

            number += 1
            date   += 2.weeks
            while (date.month == 12 && (22..31).cover?(date.day)) || (date.month == 1 && (1..4).cover?(date.day))
              date += 1.weeks
            end
          end
        end
      end
    end
  end
end
