#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :plugin, "Whether or not this is a ManageIQ plugin", :type => :boolean, :required => true

  ManageIQ::Release.common_options(self, :except => :repo_set)
end

repo_name = opts[:repo].first
repo = ManageIQ::Release.repo_for(repo_name)

has_repo = !opts[:plugin] || ManageIQ::Release::RepoSet.config["master"].include?(repo_name)
has_labels = ManageIQ::Release::Labels.config["repos"][repo.github_repo]
unless has_repo && has_labels
  STDERR.puts "ERROR: First update config/repos.yml and config/labels.yml with the new repo"
  exit 1
end

puts "\n** Updating Repo Settings"
ManageIQ::Release::UpdateRepoSettings.new(repo.github_repo, opts).run
puts "\n** Updating Branch Protection"
ManageIQ::Release::UpdateBranchProtection.new(repo.github_repo, opts.merge(:branch => "master")).run
puts "\n** Updating Labels"
ManageIQ::Release::UpdateLabels.new(repo.github_repo, opts).run
puts "\n** Reserve rubygems entry"
if opts[:plugin]
  ManageIQ::Release::RubygemsStub.new(repo.name, opts).run
end

puts "\n** Preparing Pull Request"
ManageIQ::Release::PullRequestBlasterOuter.new(repo, opts.merge(
  :base    => "master",
  :head    => "new_plugin_repo",
  :script  => "scripts/pull_request_blaster_outer/new_plugin_repo.rb",
  :message => "Prepare new repository"
)).blast

puts
puts "******* MANUAL THINGS *******"
puts "- Add repo to repos.sets.yml if this is a new core or provider plugin"
puts "- Add repo to mirror settings"
puts "- https://codeclimate.com/github/#{repo.github_repo} => Repo Settings => GitHub => Pull Request Status Updates => Install"
puts "  - Ensure that CC_TEST_REPORTER_ID is set in the repo settings"
puts "- https://gitter.im/ManageIQ#createroom and create a new room linked to the repository"
puts "- Add repo to the bot"
puts "  - Also add repo to the bot settings"
