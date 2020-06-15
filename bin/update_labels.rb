#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :repo, "The repo to update. If not passed, will try all repos in config/labels.yml", :type => :strings
  opt :dry_run, "", :default => false
end
opts[:repo] ||= ManageIQ::Release::Labels.all.keys

ManageIQ::Release.each_repo(opts[:repo]) do |repo|
  expected_labels = ManageIQ::Release::Labels[repo.github_repo]

  if expected_labels.nil?
    puts "** No labels defined for #{repo.github_repo}"
  else
    ManageIQ::Release::UpdateLabels.new(repo.github_repo, expected_labels, opts.slice(:dry_run)).run
  end
end
