#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'trollop'

opts = Trollop.options do
  opt :new, "The new milestone name", :type => :string, :required => true
  opt :old, "The old milestone name", :type => :string, :required => true

  opt :dry_run, "", :default => false
end

rename_hash = { opts[:old] => opts[:new] }

puts "Dry Run = #{opts[:dry_run].inspect}"

repos = ManageIQ::Release::Repos["master"]
repos.each do |repo|
  puts ManageIQ::Release.header(repo.name)
  ManageIQ::Release::RenameSprintMilestones.new(repo.github_repo, rename_hash, opts.slice(:dry_run)).run
  puts
end
