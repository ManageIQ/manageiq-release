require 'yaml'

module ManageIQ
  module Release
    class Travis
      RUBY_BASE = {
        "language"       => "ruby",
        "cache"          => "bundler",
        "rvm"            => ["2.4.5", "2.5.3"],
        "before_install" => [
          "echo 'gem: --no-ri --no-rdoc --no-document' > ~/.gemrc",
          "gem install bundler"
        ]
      }

      JS_BASE = {
        "language" => "node_js",
        "cache"    => {"directories" => ["$HOME/.npm"]},
        "node_js"  => ["10"],
        "install"  => ["npm ci"],
        "script"   => ["npm run travis:verify"]
      }

      def self.badge_name
        "Build Status"
      end

      def self.badge_details(repo, branch)
        {
          "description" => badge_name,
          "image"       => "https://travis-ci.org/#{repo.github_repo}.svg?branch=#{branch}",
          "url"         => "https://travis-ci.org/#{repo.github_repo})"
        }
      end

      attr_reader :repo, :dry_run

      def initialize(repo, dry_run: false)
        @repo    = repo
        @dry_run = dry_run
        @yaml    = nil
      end

      def init_yaml(language:)
        @yaml =
          case language.to_s
          when "ruby"    then RUBY_BASE.dup
          when "node_js" then JS_BASE.dup
          else raise ArgumentError, "language must be either 'ruby' or 'node_js"
          end
      end

      def to_yaml
        raise "you must call init_yaml before dumping it" if @yaml.nil?
        @yaml.to_yaml
      end

      def save!
        repo.write_file(".travis.yml", to_yaml, dry_run: dry_run)

        save_deploy_files! if @deploy
      end

      def add_postgres!(production_db:, version: "9.5")
        return if @postgres
        (@yaml["addons"] ||= {})["postgresql"] = version
        (@yaml["before_install"] ||= []) << %Q(DATABASE_URL="postgresql://postgres:@localhost:5432/#{production_db}?encoding=utf8&pool=5&wait_timeout=5)
        (@yaml["before_script"] ||= []) << "bundle exec rake db:create db:migrate"
        @postgres = true
      end

      def add_codeclimate!
        return if @code_climate
        @yaml["before_script"] ||= []
        @yaml["before_script"]  += [
          "curl -L https://codeclimate.com/downloads/test-reporter/test-reporter-latest-linux-amd64 > ./cc-test-reporter",
          "chmod +x ./cc-test-reporter",
          "./cc-test-reporter before-build"
        ]
        (@yaml["after_script"] ||= []) << "./cc-test-reporter after-build --exit-code $TRAVIS_TEST_RESULT"
        @code_climate = true
      end

      def add_deploy!(build_repo, ssh_key)
        return if @deploy
        (@yaml["after_success"] ||= []) << "curl -sSL https://raw.githubusercontent.com/RedHatInsights/insights-frontend-builder-common/master/src/bootstrap.sh | bash -s"
        @deploy = true
      end

      def badge_details
        self.class.badge_details(repo, "master")
      end

      def enable
        if dry_run
          puts "** dry-run: travis login --github-token $GITHUB_API_TOKEN"
          puts "** dry-run: travis enable --org"
        else
          `travis login --github-token $GITHUB_API_TOKEN`
          `travis enable --org`
        end
      end

      def set_env(hash)
        hash.each do |key, value|
          if dry_run
            puts "** dry-run: travis env set #{key} #{value}"
          else
            `travis env set #{key} #{value}`
          end
        end
      end

      private

      def encrypt_file(source, dest)
        return if source.nil? || File.exist?("#{dest}.enc")

        if dry_run
          puts "** dry-run: Writing #{dest}.enc..."
        else
          FileUtils.cp(source, dest)
          `travis encrypt-file #{dest}`
          FileUtils.rm_f(dest)
        end
      end

      def create_custom_release
        repo.write_file(".travis/custom_release.sh", <<~EOF, :dry_run => dry_run, :perm => 0755)
#!/usr/bin/env bash

NODE_ENV=production npm run build

# If current dev branch is master, push to build repo ci-stable
if [ "${TRAVIS_BRANCH}" = "master" ]; then
    .travis/release.sh "ci-stable"
fi

# If current dev branch is deployment branch, push to build repo
if [[ "${TRAVIS_BRANCH}" = "ci-beta"  || "${TRAVIS_BRANCH}" = "qa-beta" || "${TRAVIS_BRANCH}" = "qa-stable" || "${TRAVIS_BRANCH}" = "prod-beta" || "${TRAVIS_BRANCH}" = "prod-stable" ]]; then
    .travis/release.sh "${TRAVIS_BRANCH}"
fi
        EOF
      end

      def update_package_json
        require 'json'
        json = JSON.parse(repo.path.join("package.json"))
        json["name"] = repo.github_repo.split("/").last.chomp("-ui")
        json["insights"] = {"appname" => json["name"].sub("_", "-")}
        repo.write_file("package.json", json.to_json(indent: "  ", object_nl: "\n", array_nl: "\n", space: " "), dry_run: dry_run)
      end

      def save_deploy_files(build_repo, ssh_key)
        Dir.chdir(repo.path) do
          FileUtils.mkdir_p(".travis") unless dry_run
          encrypt_file(ENV["DEPLOY_SSH_KEY"], ".travis/deploy_key")
          create_custom_release
          update_package_json
        end
      end
    end
  end
end
