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
        number, _start_date, end_date = sprints.first
        build_title(number, end_date)
      end

      def self.build_title(number, end_date)
        "Sprint #{number} Ending #{end_date.strftime("%b %-d, %Y")}"
      end

      def self.sprints(as_of: Date.today)
        as_of ||= Date.new(0)

        require "active_support/core_ext/numeric/time"
        # The first date when we started doing this cadence
        number     = 76
        start_date = Date.parse("Dec 12, 2017")
        end_date   = Date.parse("Jan 1, 2018")

        Enumerator.new do |y|
          loop do
            y << [number, start_date, end_date] if end_date >= as_of

            number += 1
            start_date = end_date + 1.day

            end_date += 2.weeks
            while (end_date.month == 12 && (22..31).cover?(end_date.day)) ||
                  (end_date.month == 1 && (1..4).cover?(end_date.day))
              end_date += 1.weeks
            end
          end
        end
      end
    end
  end
end
