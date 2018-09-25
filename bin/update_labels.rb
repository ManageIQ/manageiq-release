#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'trollop'

opts = Trollop.options do
  opt :repo, "The repo to update. If not passed, will try all repos in config/repos.yml", :type => :string

  opt :dry_run, "", :default => false
end

ManageIQ::Release.each_repo(opts[:repo]) do |repo|
  expected_labels = ManageIQ::Release::Labels[repo.name]
  if expected_labels.nil?
    puts "** No labels defined for #{repo.name}"
  else
    ManageIQ::Release::UpdateLabels.new(repo.github_repo, expected_labels, opts.slice(:dry_run)).run
  end
end
