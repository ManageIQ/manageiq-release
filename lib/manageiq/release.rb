require 'pathname'

require 'manageiq/release/labels'
require 'manageiq/release/repo'
require 'manageiq/release/repos'

require 'manageiq/release/code_climate'
require 'manageiq/release/hakiri'
require 'manageiq/release/license'
require 'manageiq/release/readme_badges'
require 'manageiq/release/travis'

require 'manageiq/release/destroy_tag'
require 'manageiq/release/git_mirror'
require 'manageiq/release/pull_request_blaster_outer'
require 'manageiq/release/release_branch'
require 'manageiq/release/release_milestone'
require 'manageiq/release/release_tag'
require 'manageiq/release/rename_labels'
require 'manageiq/release/update_branch_protection'
require 'manageiq/release/update_labels'
require 'manageiq/release/update_repo_settings'

module ManageIQ
  module Release
    CONFIG_DIR = Pathname.new("../../config").expand_path(__dir__)
    REPOS_DIR = Pathname.new("../../repos").expand_path(__dir__)

    #
    # CLI helpers
    #

    def self.each_repo(repo_names, branch = "master")
      raise "no block given" unless block_given?
      repos_for(repo_names, branch).each do |repo|
        puts header(repo.github_repo)
        yield repo
        puts
      end
    end

    def self.repos_for(repo_names, branch = "master")
      if repo_names
        Array(repo_names).collect do |repo_name|
          org, repo = repo_name.split("/").unshift(nil).last(2)
          ManageIQ::Release::Repo.new(repo, :org => org)
        end
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

    def self.config_files_for(prefix)
      Dir.glob(CONFIG_DIR.join("#{prefix}*.yml")).sort
    end

    def self.load_config_file(prefix)
      config_files_for(prefix).each_with_object({}) do |f, h|
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
