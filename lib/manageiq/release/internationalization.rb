module ManageIQ
  module Release
    class Internationalization

      attr_reader :branch, :dry_run

      def initialize(branch: nil, dry_run: true, **_)
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

      class RepoBase
        attr_reader :branch, :dry_run

        def initialize(branch: nil, dry_run: true)
          @branch  = branch || 'master'
          @dry_run = dry_run
        end

        def repo
          @repo ||= Repo.new(github_slug)
        end

        def github_slug
          "ManageIQ/#{repo_name}"
        end

        def execute(command, description = nil)
          description ||= "*** Running `#{command}` ***"
          puts description
          system!(command)
        end

        def system!(*args)
          exit($?.exitstatus) unless system(*args)
        end

        def git_diff_stats(repo)
          repo.git.capturing.diff(:numstat => true).split("\n").each_with_object({}) do |diff, stats|
            insertions, deletions, fname = diff.split("\s")
            stats[fname] = {:insertions => insertions.to_i, :deletions => deletions.to_i }
          end
        end

        def message_catalog_file_git_stats
          diffs = git_diff_stats(repo)
          return nil if diffs.length != 1
          return nil unless diffs.key?(message_catalog_filename)
          diffs[message_catalog_filename]
        end

        def message_catalog_file_needs_commit?
          stats = message_catalog_file_git_stats
          puts "+#{stats[:insertions]}, -#{stats[:deletions]} for #{message_catalog_filename}" if stats
          stats
        end

        def message_catalog_filename
          "#{locale_dir}/#{repo_name}.pot"
        end

        def with_checked_out_repo(repo, branch)
          repo.fetch
          # repo.clean
          repo.checkout(branch)
          repo.chdir { yield }
        end

        def upload_message_catalog
          execute("tx push --source", "Uploading #{message_catalog_filename} to Transifex") if File.exist?(".tx/config")
        end

        def update_message_catalog
          with_checked_out_repo(repo, branch) do
            generate_message_catalog
            upload_message_catalog unless dry_run
          end
        end
      end

      class ManageIQ < RepoBase
        def repo_name
          'manageiq'
        end

        def locale_dir
          'locale'
        end

        def message_catalog_file_needs_commit?
          stats = super
          return false if stats.nil?

          # If the only changes are to POT-Creation-Date and PO-Revision-Date,
          # then there are no substantive changes
          # Hence why this code checks for precisely 2 insertions and deletions
          (stats[:insertions] != 2) || (stats[:deletions] != 2)
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

            execute "RAILS_ENV=i18n SKIP_TEST_RESET=true bin/setup"
            execute "bundle exec rake locale:update_all"

            puts "*** Resetting changes to files other than message catalog ***"
            git_diff_stats(repo).each do |fname, stats|
              next if fname.end_with?(message_catalog_filename)
              execute("git checkout HEAD -- #{fname}", "- resetting #{fname}")
            end
          end
        end
      end

      class ManageIQ_ServiceUI < RepoBase
        def repo_name
          'manageiq-ui-service'
        end

        def locale_dir
          'client/gettext/po'
        end

        def generate_message_catalog
          execute "yarn install"
          execute "yarn gettext:extract"
        end
      end
    end
  end
end
