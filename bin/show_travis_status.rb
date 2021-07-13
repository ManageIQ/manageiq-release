#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'more_core_extensions/core_ext/array/tableize'
require 'travis'
require 'travis/pro/auto_login'
require 'optimist'

opts = Optimist.options do
  opt :ref, "The branch or release tag to check status for.", :type => :string, :required => true

  ManageIQ::Release.common_options(self, :except => :dry_run, :repo_set_default => nil)
end
opts[:repo_set] = opts[:ref].split("-").first unless opts[:repo] || opts[:repo_set]

ManageIQ::Release::StringFormatting.enable

travis_repos = ManageIQ::Release.repos_for(opts).collect do |repo|
  next if repo.options.has_real_releases

  repo = Travis::Pro::Repository.find(repo.github_repo)
  begin
    last_build = repo.last_on_branch(opts[:ref])
  rescue Travis::Client::NotFound
    # Ignore repo which doesn't have Travis enabled for that branch
    next
  end

  status, status_sort =
    case last_build.state
    when "errored", "failed"
      [last_build.state.red, 0]
    when "created", "started"
      [last_build.state.yellow, 1]
    when "passed"
      [last_build.state.green, 2]
    else
      [last_build.state, 3]
    end

  last_build_url = "https://travis-ci.com/github/#{last_build.repository.slug}/builds/#{last_build.id}"
  {"Repo" => repo.name, "Status" => status, "Status Sort" => status_sort, "Date" => last_build.finished_at, "URL" => last_build_url}
end.compact

travis_repos.sort_by! { |v| [ v["Status Sort"], v["Date"] ] }
puts travis_repos.tableize(:columns => ["Repo", "Status", "Date", "URL"])
