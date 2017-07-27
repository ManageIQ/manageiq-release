#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'trollop'

opts = Trollop.options do
  opt :dry_run, "", :default => false
  opt :repo, "The repo to update. If not passed, will try all repos in config/repos.yml", :type => :string
end

if opts[:repo]
  repos = [ManageIQ::Release::Repo.new(opts[:repo])]
else
  repos = ManageIQ::Release::Repos["master"]
end

repos.each do |repo|
  puts ManageIQ::Release.header(repo.name)
  expected_labels = ManageIQ::Release::Labels[repo.name]
  if expected_labels.nil?
    puts "** No labels defined for #{repo.name}"
  else
    ManageIQ::Release::UpdateLabels.new(repo.github_repo, expected_labels, opts.slice(:dry_run)).run
  end
  puts
end
