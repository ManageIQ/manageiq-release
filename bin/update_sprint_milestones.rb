#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'trollop'

opts = Trollop.options do
  opt :title, "The milestone to create", :type => :string, :required => true
  opt :repo, "The repo to update. If not passed, will try all repos in config/repos.yml", :type => :string

  opt :dry_run, "", :default => false
end

ManageIQ::Release.each_repo(opts[:repo]).each do |repo|
  ManageIQ::Release::UpdateSprintMilestones.new(repo.github_repo, opts.slice(:title, :dry_run)).run
end
