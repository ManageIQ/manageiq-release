module ManageIQ
  module Release
    class ReleaseBranch
      attr_reader :repo, :branch, :dry_run

      def initialize(repo, branch:)
        @repo    = repo
        @branch  = branch
      end

      def run
        repo.fetch
        repo.checkout(branch, "origin/master")

        Dir.chdir(repo.path) do
          changes = edit_bin_setup
          changes = edit_readme || changes

          if changes
            repo.git.add(".")
            repo.git.commit("-m", "Changes for #{branch} branch release.")
          end
        end
      end

      def review
        repo.git.capturing.log("-1", "-p", :graph => true, :pretty => "format:\%h -\%d \%s (\%cr) <\%an>")
      end

      def post_review
        # TODO: Automate this with some questions at branch time
        "pushd #{repo.path}; OVERRIDE=true git push origin #{branch}; popd"
      end

      private

      def edit_bin_setup
        editing_file("bin/setup") do |contents|
          contents.sub(/(git clone.+? --branch )master/, "\\1#{branch}")
        end
      end

      def edit_readme
        editing_file("README.md") do |contents|
          contents.gsub!(/(travis-ci\.org.+?branch=)master\b/, "\\1#{branch}")
          contents.gsub!(/(travis-ci\.org.+?\.svg)\)/, "\\1?branch=#{branch})")
          contents.gsub!(/(hakiri\.io.+?\/)master\b/, "\\1#{branch}")
          contents.gsub!(/(coveralls\.io.+?branch=)master\b/, "\\1#{branch}")
          contents.gsub!(/(buildstats\.info.+?branch=)master\b/, "\\1#{branch}")
          contents
        end
      end

      def editing_file(file)
        return false unless File.exist?(file)

        contents = File.read(file)
        new_contents = yield contents.dup

        if new_contents != contents
          File.write(file, new_contents)
          true
        else
          false
        end
      end
    end
  end
end
