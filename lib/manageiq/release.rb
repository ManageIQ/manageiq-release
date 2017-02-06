require 'manageiq/release/repo'
require 'manageiq/release/repos'

require 'manageiq/release/destroy_tag'
require 'manageiq/release/release_tag'
require 'manageiq/release/update_sprint_milestones'

module ManageIQ
  module Release
    HEADER = ("=" * 80).freeze
    SEPARATOR = ("*" * 80).freeze

    #
    # Logging helpers
    #

    def self.header(title)
      title = " #{title} "
      start = (HEADER.length / 2) - (title.length / 2)
      HEADER.dup.tap { |h| h[start, title.length] = title }
    end

    def self.separator
      SEPARATOR
    end

    #
    # Configuration
    #

    def self.github_api_token
      @github_api_token ||= ENV["GITHUB_API_TOKEN"]
    end

    def self.github_api_token=(token)
      @github_api_token = token
    end

    #
    # Services
    #

    def self.github
      @github ||= begin
        raise "Missing GitHub API Token" if github_api_token.nil?

        require 'octokit'
        Octokit::Client.new(
          :access_token  => github_api_token,
          :auto_paginate => true
        )
      end
    end
  end
end
