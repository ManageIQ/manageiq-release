module ManageIQ
  module Release
    class RenameSprintMilestones
      attr_reader :repo, :rename_hash, :dry_run

      def initialize(repo, rename_hash, dry_run: false)
        @repo        = repo
        @rename_hash = rename_hash
        @dry_run     = dry_run

        invalid = rename_hash.values.reject { |new_title| SprintMilestone.valid_title?(new_title) }
        raise "Invalid title #{invalid.inspect}" if invalid.any?
      end

      def run
        rename_hash.each do |old_title, new_title|
          github_milestone = existing_milestones[old_title]
          update(github_milestone.number, old_title, new_title) if github_milestone
        end
      end

      private

      def existing_milestones
        @existing_milestones ||= SprintMilestone.all(repo, :state => :all).index_by(&:title)
      end

      def update(old_number, old_title, new_title)
        puts "Renaming #{old_title.inspect} (number: #{old_number}) to #{new_title.inspect}"

        due_date = SprintMilestone.due_date_from_title(new_title)

        if dry_run
          puts "** dry-run: github.update_milestone(#{repo.inspect}, #{old_number.inspect}, :title => #{new_title.inspect}, :due_on => #{due_date.inspect})"
        else
          github.update_milestone(repo, old_number, :title => new_title, :due_on => due_date)
        end
      end

      def github
        ManageIQ::Release.github
      end
    end
  end
end
