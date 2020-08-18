module ManageIQ
  module Release
    class Internationalization

      attr_reader :branch, :dry_run

      def initialize(branch: nil, dry_run: true)
        @branch  = branch || 'master'
        @dry_run = dry_run
      end

      # In ManageIQ/manageiq repo, run `rake locale:update`
      # In ManageIQ/manageiq-ui-service repo, run `gulp gettext-extract`
      # If there are material differences, push up to Transifex
      def update_message_catalogs
        generate_message_catalog_for_manageiq
        generate_message_catalog_for_manageiq_service_ui
      end

      private

      def execute(command, description = nil)
        description ||= "*** Running `#{command}` ***"
        puts description
        system(command)
      end

      def git_diff_stats(repo)
        repo.git.capturing.diff(:numstat => true).split("\n").each_with_object({}) do |diff, stats|
          insertions, deletions, fname = diff.split("\s")
          stats[fname] = {:insertions => insertions.to_i, :deletions => deletions.to_i }
        end
      end

      # ManageIQ Section

      def create_database_yml
        puts "*** Creating config/database.yml ***"
        database_config = YAML.load_file("config/database.pg.yml")
        unless database_config.key?('i18n')
          database_config['i18n'] = database_config['test'].dup
          database_config['i18n']['database'] = "vmdb_i18n"
        end
        File.write("config/database.yml", database_config.to_yaml)
      end

      def manageiq_message_catalog_filename
        "locale/manageiq.pot"
      end

      def manageiq_message_catalog_file_needs_commit?
        needs_commit = false
        diffs = git_diff_stats(manageiq_repo)
        return false if diffs.length != 1
        return false unless diffs.key?(manageiq_message_catalog_filename)
        stats = diffs[manageiq_message_catalog_filename]
        puts "+#{stats[:insertions]}, -#{stats[:deletions]} for #{manageiq_message_catalog_filename}"

        # If the only changes are to POT-Creation-Date and PO-Revision-Date,
        # then there are no substantive changes
        # Hence why this code checks for precisely 2 insertions and deletions
        (stats[:insertions] != 2) || (stats[:deletions] != 2)
      end

      def manageiq_repo_path
        manageiq_repo.path || File.join(__dir__, "../../../repos/ManageIQ/manageiq")
      end

      def manageiq_repo
        @manageiq_repo ||= Repo.new('ManageIQ/manageiq')
      end

      def generate_message_catalog_for_manageiq
        Bundler.with_clean_env do
          manageiq_repo.fetch
          manageiq_repo.checkout(branch)

          Dir.chdir(manageiq_repo_path) do |dir|
            create_database_yml

            execute "RAILS_ENV=i18n SKIP_TEST_RESET=true bin/setup"
            execute "bundle exec rake locale:update"

            puts "*** Resetting changes to files other than message catalog ***"
            git_diff_stats(manageiq_repo).each do |fname, stats|
              next if fname.end_with?(manageiq_message_catalog_filename)
              puts "- resetting #{fname}"
              system("git checkout HEAD -- #{fname}")
            end

            puts "*** Checking #{manageiq_message_catalog_filename} file ***"
            puts "#{manageiq_message_catalog_filename} needs commit?: #{manageiq_message_catalog_file_needs_commit? ? 'YES' : 'NO'}"
          end
        end
      end

      # ManageIQ Service UI Section

      def manageiq_service_ui_repo
        @manageiq_service_ui_repo ||= Repo.new('ManageIQ/manageiq-ui-service')
      end

      def manageiq_service_ui_message_catalog_filename
        "client/gettext/po/manageiq-ui-service.pot"
      end

      def manageiq_service_ui_message_catalog_file_needs_commit?
        needs_commit = false
        diffs = git_diff_stats(manageiq_service_ui_repo)
        return false if diffs.length != 1
        return false unless diffs.key?(manageiq_service_ui_message_catalog_filename)
        stats = diffs[manageiq_service_ui_message_catalog_filename]
        puts "+#{stats[:insertions]}, -#{stats[:deletions]} for #{manageiq_service_ui_message_catalog_filename}"
        return true
      end

      def generate_message_catalog_for_manageiq_service_ui
        Bundler.with_clean_env do
          manageiq_service_ui_repo.fetch
          manageiq_service_ui_repo.checkout(branch)

          Dir.chdir(manageiq_service_ui_repo.path) do |dir|
            execute "yarn install"
            execute "yarn gettext:extract"
            puts "*** Checking #{manageiq_service_ui_message_catalog_filename} file ***"
            puts "#{manageiq_service_ui_message_catalog_filename} needs commit?: #{manageiq_service_ui_message_catalog_file_needs_commit? ? 'YES' : 'NO'}"
          end
        end
      end
    end
  end
end
