#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'trollop'

opts = Trollop.options do
  opt :dry_run, "", :default => false
end

repos = ManageIQ::Release::Repos["master"]
repos.each do |repo|
  puts ManageIQ::Release.header(repo.name)
  expected_labels = ManageIQ::Release::Labels[repo.name]
  ManageIQ::Release::UpdateLabels.new(repo.github_repo, expected_labels, opts.slice(:dry_run)).run
  puts
end
