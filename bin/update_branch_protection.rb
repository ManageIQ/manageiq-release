#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'trollop'

opts = Trollop.options do
  opt :branch, "The branch to protect.", :type => :string, :required => true
  opt :repo, "The repo to update. If not passed, will try all repos for the branch specified.", :type => :string

  opt :dry_run, "", :default => false
end

ManageIQ::Release.each_repo(opts[:repo], opts[:branch]) do |repo|
  skip = opts[:branch] != "master" && repo.options[:has_real_releases]
  ManageIQ::Release::UpdateBranchProtection.new(repo.github_repo, opts.slice(:branch, :dry_run)).run unless skip
end
