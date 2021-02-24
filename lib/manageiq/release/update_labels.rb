module ManageIQ
  module Release
    class UpdateLabels
      attr_reader :repo, :dry_run, :expected_labels

      def initialize(repo, dry_run: false, **_)
        @repo            = repo
        @dry_run         = dry_run
        @expected_labels = ManageIQ::Release::Labels[repo]
      end

      def run
        if expected_labels.nil?
          puts "** No labels defined for #{repo}"
          return
        end

        expected_labels.each do |label, color|
          github_label = existing_labels.detect { |l| l.name == label }

          if !github_label
            create(label, color)
          elsif github_label.color.downcase != color.downcase
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

        # Temporary HACK until https://github.com/octokit/octokit.rb/pull/1297 is merged and released
        require "erb"
        label = ERB::Util.url_encode(label)

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
