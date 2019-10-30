#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :title, "The milestone to create", :type => :string
  opt :scheduled, "Used for scheduled updates and will auto calculate the title", :default => false

  opt :repo, "The repo to update. If not passed, will try all repos in config/repos.yml", :type => :strings
  opt :dry_run, "", :default => false
end

opts[:title] = ManageIQ::Release::SprintMilestone.next_title if opts[:scheduled]
Optimist.die "option --title must be specified" if opts[:title].nil?

ManageIQ::Release.each_repo(opts[:repo]) do |repo|
  ManageIQ::Release::UpdateSprintMilestones.new(repo.github_repo, opts.slice(:title, :dry_run)).run
end
