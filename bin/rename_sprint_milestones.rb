#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :new,  "The new milestone name", :type => :string, :required => true
  opt :old,  "The old milestone name", :type => :string, :required => true

  opt :repo, "The repo to update. If not passed, will try all repos in config/repos.yml", :type => :strings
  opt :dry_run, "", :default => false
end

rename_hash = { opts[:old] => opts[:new] }

ManageIQ::Release.each_repo(opts[:repo]) do |repo|
  ManageIQ::Release::RenameSprintMilestones.new(repo.github_repo, rename_hash, opts.slice(:dry_run)).run
end
