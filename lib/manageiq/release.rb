require 'pathname'
require 'pp'

require 'manageiq/release/labels'
require 'manageiq/release/repo'
require 'manageiq/release/repo_set'

require 'manageiq/release/code_climate'
require 'manageiq/release/hakiri'
require 'manageiq/release/license'
require 'manageiq/release/readme_badges'
require 'manageiq/release/travis'

require 'manageiq/release/string_formatting'

require 'manageiq/release/backport_prs'
require 'manageiq/release/destroy_tag'
require 'manageiq/release/git_mirror'
require 'manageiq/release/internationalization'
require 'manageiq/release/pull_request_blaster_outer'
require 'manageiq/release/release_branch'
require 'manageiq/release/release_tag'
require 'manageiq/release/rename_labels'
require 'manageiq/release/rubygems_stub'
require 'manageiq/release/update_branch_protection'
require 'manageiq/release/update_labels'
require 'manageiq/release/update_milestone'
require 'manageiq/release/update_repo_settings'
require 'manageiq/release/update_travis_settings'

module ManageIQ
  module Release
    CONFIG_DIR = Pathname.new("../../config").expand_path(__dir__)
    REPOS_DIR = Pathname.new("../../repos").expand_path(__dir__)

    #
    # CLI helpers
    #

    def self.each_repo(**kwargs)
      raise "no block given" unless block_given?

      repos_for(**kwargs).each do |repo|
        puts header(repo.github_repo)
        yield repo
        puts
      end
    end

    def self.repos_for(repo: nil, repo_set: nil, **_)
      Optimist.die("options --repo or --repo_set must be specified") unless repo || repo_set

      if repo
        Array(repo).map { |n| repo_for(n) }
      else
        ManageIQ::Release::RepoSet[repo_set]
      end
    end

    def self.repo_for(repo)
      Optimist.die(:repo, "must be specified") if repo.nil?

      org, repo_name = repo.split("/").unshift(nil).last(2)
      ManageIQ::Release::Repo.new(repo_name, :org => org)
    end

    def self.common_options(optimist, only: %i[repo repo_set dry_run], except: nil, repo_set_default: "master")
      optimist.banner("")
      optimist.banner("Common Options:")

      subset = Array(only).map(&:to_sym) - Array(except).map(&:to_sym)

      if subset.include?(:repo_set)
        optimist.opt :repo_set, "The repo set to work with", :type => :string, :default => repo_set_default, :short => "s"
      end
      if subset.include?(:repo)
        msg = "Individual repo(s) to work with"
        if subset.include?(:repo_set)
          sub_opts = {}
          msg << "; Overrides --repo-set"
        else
          sub_opts = {:required => true}
        end
        optimist.opt :repo, msg, sub_opts.merge(:type => :strings)
      end
      if subset.include?(:dry_run)
        optimist.opt :dry_run, "Execute without making changes", :default => false
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

    def self.travis_api_token
      @travis_api_token ||= ENV["TRAVIS_API_TOKEN"]
    end

    def self.travis_api_token=(token)
      @travis_api_token = token
    end

    #
    # Services
    #

    def self.github
      @github ||= begin
        raise "Missing GitHub API Token" if github_api_token.nil?

        params = {
          :access_token  => github_api_token,
          :auto_paginate => true
        }
        params[:api_endpoint] = ENV["GITHUB_API_ENDPOINT"] if ENV["GITHUB_API_ENDPOINT"]

        require 'octokit'
        Octokit::Client.new(params)
      end
    end

    def self.github_repo_names_for(org)
      github
        .list_repositories(org, :type => "sources")
        .reject { |r| r.fork? || r.archived? }
        .map { |r| "#{org}/#{r.name}" }
    end

    def self.travis
      @travis ||= begin
        raise "Missing Travis API Token" if travis_api_token.nil?

        require 'travis/client'
        ::Travis::Client.new(
          :uri           => ::Travis::Client::COM_URI,
          :access_token  => travis_api_token
        )
      end
    end
  end
end
