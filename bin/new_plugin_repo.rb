#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  ManageIQ::Release.common_options(self, :except => :repo_set)
end

repo = ManageIQ::Release.repo_for(opts[:repo])
labels = ManageIQ::Release::Labels[repo.github_repo]
unless repo && labels
  STDERR.puts "ERROR: First update config/repos.yml and config/labels.yml with the new repo"
  exit 1
end

puts "\n** Updating Repo Settings"
ManageIQ::Release::UpdateRepoSettings.new(repo.github_repo, opts.slice(:dry_run)).run
puts "\n** Updating Branch Protection"
ManageIQ::Release::UpdateBranchProtection.new(repo.github_repo, opts.slice(:dry_run).merge(:branch => "master")).run
puts "\n** Updating Labels"
ManageIQ::Release::UpdateLabels.new(repo.github_repo, opts.slice(:dry_run)).run

puts "\n** Preparing Pull Request"
ManageIQ::Release::PullRequestBlasterOuter.new(repo, opts.slice(:dry_run).merge(
  :base    => "master",
  :head    => "new_plugin_repo",
  :script  => "scripts/pull_request_blaster_outer/new_plugin_repo.rb",
  :message => "Prepare initial third party services"
)).blast

puts
puts "******* MANUAL THINGS *******"
puts "Go to https://codeclimate.com/github/#{repo.github_repo} => settings => GitHub => Pull Request Status Updates => Install"
puts "Enable hakiri"
puts "Add repo to the bot"
