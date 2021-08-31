module ManageIQ
  module Release
    class ReleaseBranch
      attr_reader :repo, :branch, :next_branch, :source_branch, :dry_run

      def initialize(repo, branch:, next_branch:, source_branch: "master", dry_run:, **_)
        @repo          = repo
        @branch        = branch
        @next_branch   = next_branch
        @source_branch = source_branch
        @dry_run       = dry_run

        @branch_changes = false
        @master_changes = false
      end

      def run
        repo.fetch
        repo.checkout(branch, "origin/#{source_branch}")

        repo.chdir do
          @branch_changes = apply_common_branch_changes
          @branch_changes = apply_branch_changes || @branch_changes

          @master_changes = apply_master_changes
        end
      end

      def review
        branch_diff = repo.git.capturing.log("-2", "-p", branch, :graph => true, :pretty => "format:\%h -\%d \%s (\%cr) <\%an>").chomp if @branch_changes
        master_diff = repo.git.capturing.log("-1", "-p", "master", :graph => true, :pretty => "format:\%h -\%d \%s (\%cr) <\%an>").chomp if @master_changes

        [branch_diff, master_diff].compact.join("\n\n#{ManageIQ::Release.separator("-")}\n\n")
      end

      def post_review
        # TODO: Automate this with some questions at branch time
        branches = []
        branches << branch   if @branch_changes
        branches << "master" if @master_changes
        return if branches.empty?

        "pushd #{repo.path}; OVERRIDE=true git push origin #{branches.join(" ")}; popd"
      end

      private

      def apply_common_branch_changes
        changes = edit_bin_setup
        changes = edit_readme || changes

        if changes
          repo.git.add(".")
          repo.git.commit("-m", "Changes for new branch #{branch}.")
        end

        changes
      end

      def apply_branch_changes
        return unless repo.options.has_rake_release_new_branch

        rake_release("new_branch")

        true
      end

      def apply_master_changes
        return unless repo.options.has_rake_release_new_branch_master

        repo.checkout("master", "origin/master")
        rake_release("new_branch_master")
        repo.git.checkout(branch)

        true
      end

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

      def rake_release(task)
        rake("release:#{task}", {"RELEASE_BRANCH" => branch, "RELEASE_BRANCH_NEXT" => next_branch})
      end

      def rake(task, env)
        if dry_run
          env_str = env.map { |k, v| "#{k}=#{v}" }.join(" ")

          puts "** dry-run: bundle check || bundle update"
          puts "** dry-run: #{env_str} bundle exec rake #{task}"
        else
          Bundler.with_clean_env do
            system!("bundle check || bundle update", :chdir => repo.path)
            system!(env, "bundle exec rake #{task}", :chdir => repo.path)
          end
        end
      end

      def system!(*args)
        exit($?.exitstatus) unless system(*args)
      end
    end
  end
end
