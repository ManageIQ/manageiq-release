require "active_support/core_ext/object/deep_dup"

module ManageIQ
  module Release
    class ReadmeBadges
      attr_reader :repo, :dry_run
      attr_accessor :badges

      def initialize(repo, dry_run: false, **_)
        @repo    = repo
        @dry_run = dry_run
        reload
      end

      def save!
        lines = content.lines

        apply_badges!(lines)
        save_contents!(lines.join)

        if dry_run
          reload(lines)
        else
          reload
        end

        true
      end

      def content
        return "" unless @file
        File.read(repo.path.join(@file))
      end

      private

      def reload(lines = nil)
        @file = repo.detect_readme_file if lines.nil?

        reload_badges(lines)
      end

      def reload_badges(lines)
        lines ||= content.lines
        @badges = extract_badges(lines)
        @original_badges = @badges.deep_dup
        @original_badge_indexes = @badges.map { |b| b["index"] }
      end

      def extract_badges(lines)
        lines.each.with_index.select do |l, _i|
          l.to_s.start_with?("[![")
        end.map do |l, i|
          match = l.match(/\A\[!\[(?<description>[^\]]+)\]\((?<image>[^\)]+)\)\]\((?<url>[^\)]+)\)/)
          match.named_captures.merge("index" => i)
        end
      end

      def build_badge_string(badge)
        "[![#{badge["description"]}](#{badge["image"]})](#{badge["url"]})\n"
      end

      def apply_badges!(lines)
        return if badges == @original_badges

        lines.reject!.with_index { |_l, i| @original_badge_indexes.include?(i) }

        start_index = @original_badge_indexes[0] || 2
        @badges.reverse_each do |b|
          lines.insert(start_index, build_badge_string(b))
        end
      end

      def save_contents!(contents)
        repo.rm_file("README", dry_run: dry_run)
        repo.rm_file("README.txt", dry_run: dry_run)
        repo.write_file("README.md", contents, dry_run: dry_run)
      end
    end
  end
end
