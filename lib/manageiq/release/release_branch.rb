module ManageIQ
  module Release
    class ReleaseBranch
      attr_reader :repo, :branch, :next_branch, :source_branch, :dry_run

      def self.first_time_setup(source_branch)
        return if @first_time_setup

        # Ensure we move core to the source branch so that the symlinks from the
        # other repos are correct
        core_repo = Repo.new("ManageIQ/manageiq")
        core_repo.fetch
        core_repo.checkout(source_branch, "origin/#{source_branch}")

        @first_time_setup = true
      end

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
        self.class.first_time_setup(source_branch)

        repo.fetch
        repo.checkout(branch, "origin/#{source_branch}")

        repo.chdir do
          symlink_spec_manageiq

          @branch_changes = apply_common_branch_changes
          @branch_changes = apply_branch_changes || @branch_changes

          @master_changes = apply_master_changes
        end

        # For core, ensure we move core back to the source branch so that the
        # symlinks from the other repos are correct. However, just do a regular
        # checkout and not a hard/clean checkout, as we need to keep the commits
        # to push later.
        repo.git.checkout(source_branch) if repo.github_repo == "ManageIQ/manageiq"
      end

      def pretty_log(target_branch, count)
        repo.git.capturing.log("-#{count}", "--color", "-p", target_branch, :graph => true, :pretty => "format:\%C(auto)\%h -\%d \%s \%C(green)(\%cr) \%C(cyan)<\%an>\%C(reset)").chomp
      end

      def review
        branch_diff = pretty_log(branch, 2) if @branch_changes
        master_diff = pretty_log("master", 1) if @master_changes

        [
          ManageIQ::Release.header("#{branch} changes", "-"),
          branch_diff,
          ManageIQ::Release.header("master changes", "-"),
          master_diff
        ].compact.join("\n\n")
      end

      def post_review
        # TODO: Automate this with some questions at branch time
        branches = []
        branches << branch
        branches << "master" if @master_changes
        return if branches.empty?

        "pushd #{repo.path}; OVERRIDE=true git push origin #{branches.join(" ")}; popd"
      end

      private

      def symlink_spec_manageiq
        return if repo.github_repo == "ManageIQ/manageiq"
        return unless Pathname.new("spec").directory?

        FileUtils.rm_f("spec/manageiq")
        FileUtils.ln_s("../../manageiq", "spec/manageiq")
      end

      def apply_common_branch_changes
        before_install = editing_file("bin/before_install") do |contents|
          contents.sub(/(git clone.+? --branch )#{source_branch}/, "\\1#{branch}")
        end

        readme = editing_file("README.md") do |contents|
          contents.gsub!(/(github\.com.+?branch=)#{source_branch}\b/, "\\1#{branch}")
          contents.gsub!(/(github\.com.+?\.svg)\)/, "\\1?branch=#{branch})")
          contents.gsub!(/(coveralls\.io.+?branch=)#{source_branch}\b/, "\\1#{branch}")
          contents.gsub!(/Build history for (?:master|#{source_branch}) branch/, "Build history for #{branch} branch")
          contents.gsub!(/(buildstats\.info.+?branch=)#{source_branch}\b/, "\\1#{branch}")
          contents
        end

        files_to_update = [before_install, readme].compact
        if files_to_update.any?
          repo.git.add(*files_to_update)
          repo.git.commit("-m", "Changes for new branch #{branch}.")
          true
        else
          false
        end
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

        # Go back to the previous branch
        repo.git.checkout(branch)

        true
      end

      def editing_file(file)
        return nil unless File.exist?(file)

        contents = File.read(file)
        new_contents = yield contents.dup

        if new_contents != contents
          File.write(file, new_contents)
          file
        else
          nil
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
          Bundler.with_unbundled_env do
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
