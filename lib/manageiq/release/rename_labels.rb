module ManageIQ
  module Release
    class RenameLabels
      attr_reader :repo, :rename_hash, :dry_run

      def initialize(repo, rename_hash, dry_run: false, **_)
        @repo        = repo
        @rename_hash = rename_hash
        @dry_run     = dry_run
      end

      def run
        rename_hash.each do |old_name, new_name|
          github_label = existing_labels.detect { |l| l.name == old_name }

          if github_label
            update(old_name, new_name)
          end
        end
      end

      private

      def existing_labels
        @existing_labels ||= github.labels(repo)
      end

      def update(old_label, new_label)
        puts "Renaming #{old_label.inspect} to #{new_label.inspect}"

        if dry_run
          puts "** dry-run: github.rename_label(#{repo.inspect}, #{old_label.inspect}, :name => #{new_label.inspect})"
        else
          github.update_label(repo, old_label, :name => new_label)
        end
      end

      def github
        ManageIQ::Release.github
      end
    end
  end
end
