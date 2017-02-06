#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'trollop'

opts = Trollop.options do
  opt :title, "The milestone to create", :type => :string, :required => true

  opt :dry_run, "", :default => false
end

repos = ManageIQ::Release::Repos["master"]
repos.each do |repo|
  puts ManageIQ::Release.header(repo.name)
  ManageIQ::Release::UpdateSprintMilestones.new(repo.github_repo, opts[:title], opts).run
  puts
end
