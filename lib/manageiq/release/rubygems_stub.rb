module ManageIQ
  module Release
    class RubygemsStub
      attr_reader :repo, :owners, :dry_run

      def initialize(repo, owners: [], dry_run: false, **_)
        @repo    = repo
        @owners  = owners
        @dry_run = dry_run
      end

      def run
        if stub_exists?
          puts "A stub gem for #{repo.inspect} already exists."
          return
        end

        if gem_exists?
          puts "A gem for #{repo.inspect} already exists with the following versions:"
          puts "  #{gem_versions}"
          puts
          loop do
            print "Would you still like to create a stub? (y/N) "
            answer = gets.chomp.downcase[0] || "n"
            break  if answer == "y"
            return if answer == "n"
          end
          puts
        end

        Dir.mktmpdir do |dir|
          package = create_gem(dir)
          push_gem(package)

          owners.each do |o|
            set_gem_owner(o)
          end
        end
      end

      private

      def stub_exists?
        gem_versions.include?("0.0.1")
      end

      def gem_exists?
        gem_string.presence
      end

      # Returns a gem's versions as listed by gem list
      #
      # Example (where @repo is the "foo" gem):
      #   # => ["2.1.0", "2.0.0", "1.1.0", "1.0.0"]
      def gem_versions
        gem_string.split(" ", 2).last.to_s[1..-2].to_s.split(", ")
      end

      # Returns a gem string as listed by gem list
      #
      # Example (where @repo is the "foo" gem):
      #   # => "foo (2.1.0, 2.0.0, 1.1.0, 1.0.0)"
      def gem_string
        @gem_string ||= `gem list #{repo} --exact --remote --all`.chomp.split("\n").last.to_s
      end

      def create_gem(dir)
        path = File.join(dir, "#{repo}.gemspec")
        File.write(path , <<~RUBY)
          Gem::Specification.new do |s|
            s.name        = "#{repo}"
            s.version     = "0.0.1"
            s.licenses    = ["Apache-2.0"]
            s.summary     = "#{repo}"
            s.description = s.summary
            s.authors     = ["ManageIQ Authors"]
            s.homepage    = "https://github.com/ManageIQ/#{repo}"
            s.metadata    = { "source_code_uri" => s.homepage }
          end
        RUBY

        system("gem build #{path}", :chdir => dir)

        File.join(dir, "#{repo}-0.0.1.gem")
      end

      def push_gem(package)
        if dry_run
          raise "#{package} not found" unless File.file?(package)
          puts "** dry-run: gem push #{package}"
        else
          system("gem push #{package}")
        end
      end

      def set_gem_owner(owner)
        if dry_run
          puts "** dry-run: gem owner #{repo} --add #{owner}"
        else
          system("gem owner #{repo} --add #{owner}")
        end
      end
    end
  end
end
