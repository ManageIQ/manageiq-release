module ManageIQ
  module Release
    class ReleaseTag
      attr_reader :repo, :branch, :tag

      def initialize(repo, branch, tag)
        @repo = repo
        @branch = branch
        @tag = tag
      end

      def run
        repo.fetch
        repo.checkout(branch)
        repo.options.has_rake_release ? rake_release : tagged_release
      end

      def review
        repo.git.capturing.log("-5", :graph => true, :pretty => "format:\%h -\%d \%s (\%cr) <\%an>")
      end

      def post_review
        # TODO: Automate this with some questions at tag time
        "pushd #{repo.path}; OVERRIDE=true git push origin #{branch} #{tag}; popd"
      end

      private

      def system!(*args)
        exit($CHILD_STATUS.exitstatus) unless system(*args)
      end

      def rake_release
        Bundler.with_clean_env do
          system!("bundle check || bundle update", :chdir => repo.path)
          system!({"RELEASE_VERSION" => tag}, "bundle exec rake release", :chdir => repo.path)
        end
      end

      def tagged_release
        repo.git.tag(tag)
      end
    end
  end
end
