#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'more_core_extensions/core_ext/array/tableize'
require 'travis'
require 'trollop'

opts = Trollop.options do
  opt :branch, "The branch to check status for", :type => :string, :required => true
end

branch = opts[:branch]

all_repos = ManageIQ::Release::Repos[branch]
travis_repos = all_repos.collect do |github_repo|
  repo = Travis::Repository.find("ManageIQ/#{github_repo.name}")
  next unless repo.branches && repo.branches.include?(branch)
  last_build = repo.last_on_branch(branch)
  { "Repo" => repo.name, "Status" => last_build.state, "Date" => last_build.finished_at }
end.compact

travis_repos.sort_by! { |v| [ v["Status"], v["Date"] ] }
puts travis_repos.tableize(:columns => ["Repo", "Status", "Date"])
