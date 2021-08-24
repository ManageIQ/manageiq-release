module ManageIQ
  module Release
    class ReleaseBranch
      attr_reader :repo, :branch, :source_branch

      def initialize(repo, branch:, source_branch: "master", **_)
        @repo          = repo
        @branch        = branch
        @source_branch = source_branch
      end

      def run
        repo.fetch
        repo.checkout(branch, "origin/#{source_branch}")

        repo.chdir do
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
          contents.sub(/(git clone.+? --branch )#{source_branch}/, "\\1#{branch}")
        end
      end

      def edit_readme
        editing_file("README.md") do |contents|
          contents.gsub!(/(travis-ci\.(?:org|com).+?branch=)#{source_branch}\b/, "\\1#{branch}")
          contents.gsub!(/(travis-ci\.(?:org|com).+?\.svg)\)/, "\\1?branch=#{branch})")
          contents.gsub!(/(hakiri\.io.+?\/)#{source_branch}\b/, "\\1#{branch}")
          contents.gsub!(/(coveralls\.io.+?branch=)#{source_branch}\b/, "\\1#{branch}")
          contents.gsub!(/(buildstats\.info.+?branch=)#{source_branch}\b/, "\\1#{branch}")
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
