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
      end

      def post_review
        # TODO: Automate this with some questions at branch time
        "pushd #{repo.path}; OVERRIDE=true git push origin #{branch}; popd"
      end
    end
  end
end
