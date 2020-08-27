module ManageIQ
  module Release
    class License
      attr_reader :repo, :dry_run

      def initialize(repo, dry_run: false, **_)
        @repo    = repo
        @dry_run = dry_run
        reload
      end

      def save!
        save_license!
        save_readme_license!
        reload unless dry_run
        true
      end

      def content
        @license.text
      end

      def license
        @license.key
      end

      def license=(value)
        @license = Licensee::License.new(value)
      end

      private

      def reload
        require 'licensee'
        @license = Licensee.license(repo.path.to_s)
      end

      def save_license!
        repo.rm_file("LICENSE.md", dry_run: dry_run)
        repo.rm_file("LICENSE", dry_run: dry_run)
        repo.write_file("LICENSE.txt", content, dry_run: dry_run)
      end

      def save_readme_license!
        readme_file = repo.detect_readme_file
        lines = readme_file ? File.read(repo.path.join(readme_file)).lines : []
        readme_file ||= "README.md"

        apply_readme_license!(lines)
        repo.write_file(readme_file, lines.join, dry_run: dry_run)
      end

      def extract_readme_license(lines)
        section = lines.each.with_index.drop_while do |l, _i|
          !l.downcase.include?("## license")
        end.take_while.with_index do |(l, _i), i2|
          i2 == 0 || !l.start_with?("## ")
        end

        section.each { |l, _i| l =~ /(mit|apache)/i && break }
        type =
          case $1.presence&.downcase
          when "mit"    then "mit"
          when "apache" then "apache-2.0"
          end

        return type, section.map(&:last)
      end

      def license_details
        case license
        when "mit"
          {
            :name => "MIT License",
            :url  => "https://opensource.org/licenses/MIT"
          }
        when "apache-2.0"
          {
            :name => "Apache License 2.0",
            :url  => "http://www.apache.org/licenses/LICENSE-2.0"
          }
        end
      end

      def apply_readme_license!(lines)
        readme_license, readme_license_indexes = extract_readme_license(lines)
        return if readme_license == license

        details = license_details
        return unless details

        lines.reject!.with_index { |_l, i| readme_license_indexes.include?(i) }

        start_index = readme_license_indexes[0] || lines.size
        new_lines = <<~EOF.lines
## License

This project is available as open source under the terms of the [#{details[:name]}](#{details[:url]}).

EOF

        new_lines.reverse_each do |l|
          lines.insert(start_index, l)
        end
      end
    end
  end
end
