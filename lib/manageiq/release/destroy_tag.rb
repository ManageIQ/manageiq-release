module ManageIQ
  module Release
    class DestroyTag
      attr_reader :repo, :tag

      def initialize(repo, tag)
        @repo = repo
        @tag = tag
      end

      def run
        repo.checkout("master")
        destroy_tag
        # TODO: Also remove anything that rake:release might have done like creating a commit
      end

      private

      def destroy_tag
        repo.git.tag({:delete => true}, tag)
      rescue MiniGit::GitError
        nil
      end
    end
  end
end
