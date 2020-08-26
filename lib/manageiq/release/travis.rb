require 'yaml'

module ManageIQ
  module Release
    class Travis
      def self.badge_name
        "Build Status"
      end

      def self.badge_details(repo, branch)
        {
          "description" => badge_name,
          "image"       => "https://travis-ci.com/#{repo.github_repo}.svg?branch=#{branch}",
          "url"         => "https://travis-ci.com/#{repo.github_repo}"
        }
      end

      attr_reader :repo, :dry_run

      def initialize(repo, dry_run: false)
        @repo    = repo
        @dry_run = dry_run
      end

      def badge_details
        self.class.badge_details(repo, "master")
      end

      def enable
        if dry_run
          puts "** dry-run: travis login --com --github-token $GITHUB_API_TOKEN"
          puts "** dry-run: travis enable --com"
        else
          `travis login --com --github-token $GITHUB_API_TOKEN`
          `travis enable --com`
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
    end
  end
end
