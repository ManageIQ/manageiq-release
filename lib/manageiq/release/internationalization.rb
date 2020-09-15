module ManageIQ
  module Release
    class Internationalization

      attr_reader :branch, :dry_run

      def initialize(branch: nil, dry_run: true)
        @branch  = branch || 'master'
        @dry_run = dry_run
      end

      def update_message_catalogs
        klasses = []
        klasses << ManageIQ
        klasses << ManageIQ_ServiceUI

        klasses.each do |klass|
          klass.new(branch: branch, dry_run: dry_run).update_message_catalog
        end
      end

      class Helper
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

        def create_tx_config(tx_config_content)
          return if File.exist?(".tx/config")
          puts "*** Creating .tx/config ***"
          Dir.mkdir(".tx") unless Dir.exist?(".tx")
          File.write(".tx/config", tx_config_content)
        end

        def with_checked_out_repo(repo, branch)
          repo.fetch
          repo.checkout(branch)
          repo.chdir { yield }
        end
      end

      class ManageIQ
        attr_reader :branch, :dry_run, :helper

        def initialize(branch: nil, dry_run: true)
          @branch  = branch || 'master'
          @dry_run = dry_run
          @helper  = Helper.new
        end

        def repo
          @repo ||= Repo.new('ManageIQ/manageiq')
        end

        def tx_config_content
          <<~CONTENT
            [main]
            host = https://www.transifex.com

            [manageiq.manageiq-#{branch}]
            file_filter = locale/<lang>/manageiq.po
            source_file = #{message_catalog_filename}
            source_lang = en
            type = PO
          CONTENT
        end

        def message_catalog_filename
          "locale/manageiq.pot"
        end

        def message_catalog_file_needs_commit?
          needs_commit = false
          diffs = helper.git_diff_stats(repo)
          return false if diffs.length != 1
          return false unless diffs.key?(message_catalog_filename)
          stats = diffs[manageiq_message_catalog_filename]
          puts "+#{stats[:insertions]}, -#{stats[:deletions]} for #{message_catalog_filename}"

          # If the only changes are to POT-Creation-Date and PO-Revision-Date,
          # then there are no substantive changes
          # Hence why this code checks for precisely 2 insertions and deletions
          needs_commit = (stats[:insertions] != 2) || (stats[:deletions] != 2)

          puts "#{message_catalog_filename} needs commit?: #{needs_commit ? 'YES' : 'NO'}"
          needs_commit
        end

        def create_database_yml
          puts "*** Creating config/database.yml ***"
          database_config = YAML.load_file("config/database.pg.yml")
          unless database_config.key?('i18n')
            database_config['i18n'] = database_config['test'].dup
            database_config['i18n']['database'] = "vmdb_i18n"
          end
          File.write("config/database.yml", database_config.to_yaml)
        end

        def generate_message_catalog
          Bundler.with_clean_env do
            create_database_yml

            helper.execute "RAILS_ENV=i18n SKIP_TEST_RESET=true bin/setup"
            helper.execute "bundle exec rake locale:update_all"

            puts "*** Resetting changes to files other than message catalog ***"
            helper.git_diff_stats(repo).each do |fname, stats|
              next if fname.end_with?(message_catalog_filename)
              puts "- resetting #{fname}"
              system("git checkout HEAD -- #{fname}")
            end
          end
        end

        def upload_message_catalog
          puts "Uploading #{message_catalog_filename} to Transifex"
          helper.create_tx_config(tx_config_content)
          system("tx push --source")
        end

        def update_message_catalog
          helper.with_checked_out_repo(repo, branch) do
            generate_message_catalog
            upload_message_catalog unless dry_run
          end
        end
      end

      class ManageIQ_ServiceUI
        attr_reader :branch, :dry_run

        def initialize(branch: nil, dry_run: true)
          @branch  = branch || 'master'
          @dry_run = dry_run
        end

        def helper
          @helper ||= Helper.new
        end

        def repo
          @repo ||= Repo.new('ManageIQ/manageiq-ui-service')
        end

        def tx_config_content
          <<~CONTENT
            [main]
            host = https://www.transifex.com

            [manageiq-service-ui.manageiq-service-ui-#{branch}]
            file_filter = client/gettext/po/<lang>/manageiq-ui-service.po
            source_file = #{message_catalog_filename}
            source_lang = en
            type = PO
          CONTENT
        end

        def message_catalog_filename
          "client/gettext/po/manageiq-ui-service.pot"
        end

        def message_catalog_file_needs_commit?
          diffs = helper.git_diff_stats(repo)
          return false if diffs.length != 1
          return false unless diffs.key?(message_catalog_filename)
          stats = diffs[message_catalog_filename]
          puts "+#{stats[:insertions]}, -#{stats[:deletions]} for #{message_catalog_filename}"
          return true
        end

        def generate_message_catalog
          helper.execute "yarn install"
          helper.execute "yarn gettext:extract"
        end

        def upload_message_catalog
          puts "Uploading #{message_catalog_filename} to Transifex"
          helper.create_tx_config(tx_config_content)
          system("tx push --source")
        end

        def update_message_catalog
          helper.with_checked_out_repo(repo, branch) do
            generate_message_catalog
            upload_message_catalog unless dry_run
          end
        end
      end
    end
  end
end
