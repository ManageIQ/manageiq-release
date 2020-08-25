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
  ManageIQ::Release::UpdateLabels.new(repo.github_repo, opts.slice(:dry_run)).run
end
