module ManageIQ
  module Release
    class UpdateTravisSettings
      attr_reader :repo, :dry_run

      def initialize(repo, dry_run: false, **_)
        @repo    = repo
        @dry_run = dry_run
      end

      def run
        edit_travis
      end

      private

      def edit_travis
        puts "Editing #{repo}"

        settings = {
          :auto_cancel_pull_requests => true,
          :auto_cancel_pushes        => true
        }

        if dry_run
          puts "** dry-run: travis.settings.update_attributes(#{settings.inspect[1..-2]})"
        else
          travis.settings.update_attributes(settings)
        end
      end

      def travis
        @travis ||= ManageIQ::Release.travis.repo(repo)
      end
    end
  end
end
