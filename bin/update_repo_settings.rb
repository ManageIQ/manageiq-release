#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :branch, "The branch to protect.", :type => :string

  opt :repo, "The repo to update. If not passed, will try all repos for the branch specified.", :type => :strings
  opt :dry_run, "", :default => false
end
Optimist.die("Must pass either --repo or --branch") unless opts[:branch_given] || opts[:repo_given]

ManageIQ::Release.each_repo(opts[:repo], opts[:branch]) do |repo|
  ManageIQ::Release::UpdateRepoSettings.new(repo.github_repo, opts.slice(:dry_run)).run

  skip = !opts[:branch_given] || (opts[:branch] != "master" && repo.options[:has_real_releases])
  ManageIQ::Release::UpdateBranchProtection.new(repo.github_repo, opts.slice(:branch, :dry_run)).run unless skip
end
