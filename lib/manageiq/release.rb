require 'pathname'

require 'manageiq/release/labels'
require 'manageiq/release/repo'
require 'manageiq/release/repos'
require 'manageiq/release/sprint_milestone'

require 'manageiq/release/delete_sprint_milestones'
require 'manageiq/release/destroy_tag'
require 'manageiq/release/pull_request_blaster_outer'
require 'manageiq/release/release_branch'
require 'manageiq/release/release_tag'
require 'manageiq/release/rename_labels'
require 'manageiq/release/rename_sprint_milestones'
require 'manageiq/release/update_labels'
require 'manageiq/release/update_repo_settings'
require 'manageiq/release/update_sprint_milestones'

module ManageIQ
  module Release
    CONFIG_DIR = Pathname.new("../../config").expand_path(__dir__)
    REPOS_DIR = Pathname.new("../../repos").expand_path(__dir__)

    #
    # CLI helpers
    #

    def self.each_repo(repo_name, branch = "master")
      raise "no block given" unless block_given?
      repos_for(repo_name, branch).each do |repo|
        puts header(repo.name)
        yield repo
        puts
      end
    end

    def self.repos_for(repo_name, branch = "master")
      if repo_name
        [ManageIQ::Release::Repo.new(repo_name)]
      else
        ManageIQ::Release::Repos[branch]
      end
    end

    #
    # Logging helpers
    #

    HEADER = ("=" * 80).freeze
    SEPARATOR = ("*" * 80).freeze

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

    def self.load_config_file(prefix)
      Dir.glob(CONFIG_DIR.join("#{prefix}*.yml")).sort.each_with_object({}) do |f, h|
        h.merge!(YAML.load_file(f))
      end
    end

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
