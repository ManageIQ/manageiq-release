#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'trollop'

opts = Trollop.options do
  opt :branch, "The branch to protect.", :type => :string
  opt :repo, "The repo to update. If not passed, will try all repos for the branch specified.", :type => :string

  opt :dry_run, "", :default => false
end
Trollop.die("Must pass either --repo or --branch") unless opts[:branch_given] || opts[:repo_given]

if opts[:repo]
  repos = [ManageIQ::Release::Repo.new(opts[:repo])]
else
  repos = ManageIQ::Release::Repos[opts[:branch]]
end

repos.each do |repo|
  puts ManageIQ::Release.header("Updating #{repo.name}")
  ManageIQ::Release::UpdateRepoSettings.new(repo.github_repo, opts.slice(:branch, :dry_run)).run
  puts
end
