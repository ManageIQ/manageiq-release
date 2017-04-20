module ManageIQ
  module Release
    class UpdateLabels
      attr_reader :repo, :expected_labels, :dry_run

      def initialize(repo, expected_labels, dry_run: false)
        @repo            = repo
        @expected_labels = expected_labels
        @dry_run         = dry_run
      end

      def run
        expected_labels.each do |label, color|
          github_label = existing_labels.detect { |l| l.name == label }

          if !github_label
            create(label, color)
          elsif github_label.color != color
            update(label, color)
          end
        end
      end

      private

      def existing_labels
        @existing_labels ||= github.labels(repo)
      end

      def create(label, color)
        puts "Creating #{label.inspect} with #{color.inspect}"

        if dry_run
          puts "** dry-run: github.add_label(#{repo.inspect}, #{label.inspect}, #{color.inspect})"
        else
          github.add_label(repo, label, color)
        end
      end

      def update(label, color)
        puts "Updating #{label.inspect} to #{color.inspect}"

        if dry_run
          puts "** dry-run: github.update_label(#{repo.inspect}, #{label.inspect}, :color => #{color.inspect})"
        else
          github.update_label(repo, label, :color => color)
        end
      end

      def github
        ManageIQ::Release.github
      end
    end
  end
end
