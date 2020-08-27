require 'rest-client'
require 'json'
require 'more_core_extensions/core_ext/array'
require 'more_core_extensions/core_ext/hash'

module ManageIQ
  module Release
    class CodeClimate
      def self.api_token
        @api_token ||= ENV["CODECLIMATE_API_TOKEN"]
      end

      def self.api_token=(token)
        @api_token = token
      end

      def self.badge_name
        "Maintainability"
      end

      def self.badge_details(repo, token)
        {
          "description" => badge_name,
          "image"       => "https://api.codeclimate.com/v1/badges/#{token}/maintainability",
          "url"         => "https://codeclimate.com/github/#{repo.github_repo}/maintainability"
        }
      end

      def self.coverage_badge_name
        "Test Coverage"
      end

      def self.coverage_badge_details(repo, token)
        {
          "description" => coverage_badge_name,
          "image"       => "https://api.codeclimate.com/v1/badges/#{token}/test_coverage",
          "url"         => "https://codeclimate.com/github/#{repo.github_repo}/test_coverage"
        }
      end

      attr_reader :repo, :dry_run

      def initialize(repo, dry_run: false, **_)
        @repo    = repo
        @dry_run = dry_run
      end

      def save!
        write_codeclimate_yaml
        write_rubocop_yamls
      end

      def enable
        ensure_enabled
      end

      def badge_token
        ensure_enabled
        @response.fetch_path("data", 0, "attributes", "badge_token")
      end

      def badge_details
        self.class.badge_details(repo, badge_token)
      end

      def coverage_badge_details
        self.class.coverage_badge_details(repo, badge_token)
      end

      def test_reporter_id
        ensure_enabled
        @response.fetch_path("data", 0, "attributes", "test_reporter_id")
      end

      def set_travis_test_reporter_id
        Travis.new(repo, dry_run: dry_run).set_env("CC_TEST_REPORTER_ID" => test_reporter_id)
      end

      private

      def ensure_enabled
        return if @enabled

        @response =
          if dry_run
            puts "** dry-run: RestClient.get(\"https://api.codeclimate.com/v1/repos?github_slug=#{repo.github_repo}\", #{headers})"
            {"data" => [{"attributes" => {"badge_token" => "0123456789abdef01234", "test_reporter_id" => "0123456789abcedef0123456789abcedef0123456789abcedef0123456789abc"}}]}
          else
            JSON.parse(RestClient.get("https://api.codeclimate.com/v1/repos?github_slug=#{repo.github_repo}", headers))
          end

        if @response["data"].empty?
          payload = {"data" => {"type" => "repos", "attributes" => {"url" => "https://github.com/#{repo.github_repo}"}}}.to_json
          @response = JSON.parse(RestClient.post("https://api.codeclimate.com/v1/github/repos", payload, headers))
          @response["data"] = [@response["data"]]
        end

        @enabled = true
      end

      def headers
        token = self.class.api_token
        raise "Missing CodeClimate API Token" if token.nil?

        {
          :accept        => "application/vnd.api+json",
          :content_type  => "application/vnd.api+json",
          :authorization => "Token token=#{token}"
        }
      end

      def write_codeclimate_yaml
        write_generator_file(".codeclimate.yml")
      end

      def write_rubocop_yamls
        %w[.rubocop.yml .rubocop_cc.yml .rubocop_local.yml].each do |file|
          write_generator_file(file)
        end
      end

      def write_generator_file(file)
        content = RestClient.get("https://raw.githubusercontent.com/ManageIQ/manageiq/master/lib/generators/manageiq/plugin/templates/#{file}").body
        repo.write_file(file, content, dry_run: dry_run)
      end
    end
  end
end
