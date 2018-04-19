#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'trollop'

opts = Trollop.options do
  opt :repo,    "The repo to update. If not passed, will try all repos in config/repos.yml. For example: --repo manageiq or --repo miq-test/sandbox", :type => :string
  opt :branch,  "The target branch we want to open a pull request against.",                             :type => :string, :required => true
  opt :script,  "The path to the script that will update the desired files. See the scripts directory.", :type => :string, :required => true
  opt :message, "The commit message and PR title for this change.",                          :type => :string, :required => true
  opt :dry_run, "Make local changes, but don't fork, push, or create the pull request.",     :default => false
end

if opts[:repo]
  org, repo = opts[:repo].split("/")
  repos = [ManageIQ::Release::Repo.new(repo, :org => org)]
else
  repos = ManageIQ::Release::Repos["master"]
end

repos.each do |repo|
  puts ManageIQ::Release.header(repo.github_repo)
  ManageIQ::Release::PullRequestBlasterOuter.new(repo, opts.slice(:branch, :script, :dry_run, :message)).blast
end
