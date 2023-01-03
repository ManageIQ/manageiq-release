#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'more_core_extensions/core_ext/array/tableize'
require 'action_view' # For ActionView::Helpers::DateHelper
require 'travis'
require 'travis/pro/auto_login'
require 'optimist'

opts = Optimist.options do
  opt :ref, "The branch or release tag to check status for.", :type => :string, :required => true

  ManageIQ::Release.common_options(self, :except => :dry_run, :repo_set_default => nil)
end
opts[:repo_set] = opts[:ref].split("-").first unless opts[:repo] || opts[:repo_set]

ManageIQ::Release::StringFormatting.enable

date_helper = Class.new { include ActionView::Helpers::DateHelper }.new

travis_repos = ManageIQ::Release.repos_for(**opts).collect do |repo|
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

  date_sort = last_build.finished_at
  date      = "#{date_helper.time_ago_in_words(date_sort)} ago" if date_sort

  last_build_url = "https://travis-ci.com/github/#{last_build.repository.slug}/builds/#{last_build.id}"

  {
    "Repo"        => repo.name,
    "Status"      => status,
    "Status Sort" => status_sort,
    "Date"        => date,
    "Date Sort"   => date_sort,
    "URL"         => last_build_url
  }
end.compact

# Reverse sort by date then stable sort by status
travis_repos = travis_repos.sort_by { |v| v["Date Sort"].to_s }.reverse.sort_by.with_index { |v, n| [v["Status Sort"], n] }

puts travis_repos.tableize(:columns => ["Repo", "Status", "Date", "URL"])
