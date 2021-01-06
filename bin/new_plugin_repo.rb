#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  ManageIQ::Release.common_options(self, :except => :repo_set)
end

repo = ManageIQ::Release.repo_for(opts[:repo].first)
labels = ManageIQ::Release::Labels[repo.github_repo]
unless repo && labels
  STDERR.puts "ERROR: First update config/repos.yml and config/labels.yml with the new repo"
  exit 1
end

puts "\n** Updating Repo Settings"
ManageIQ::Release::UpdateRepoSettings.new(repo.github_repo, opts).run
puts "\n** Updating Branch Protection"
ManageIQ::Release::UpdateBranchProtection.new(repo.github_repo, opts.merge(:branch => "master")).run
puts "\n** Updating Labels"
ManageIQ::Release::UpdateLabels.new(repo.github_repo, opts).run
puts "\n** Updating Travis Settings"
ManageIQ::Release::UpdateTravisSettings.new(repo.github_repo, opts.merge(:branch => "master")).run

puts "\n** Preparing Pull Request"
ManageIQ::Release::PullRequestBlasterOuter.new(repo, opts.merge(
  :base    => "master",
  :head    => "new_plugin_repo",
  :script  => "scripts/pull_request_blaster_outer/new_plugin_repo.rb",
  :message => "Prepare initial third party services"
)).blast

puts
puts "******* MANUAL THINGS *******"
puts "- https://codeclimate.com/github/#{repo.github_repo} => Repo Settings => GitHub => Pull Request Status Updates => Install"
puts "- https://hakiri.io and follow the new project."
puts "- https://gitter.im/ManageIQ#createroom and create a new room linked to the repository"
puts "- Add repo to https://github.com/ManageIQ/manageiq-release/blob/master/config/repos.yml"
puts "- Add repo to the bot"
