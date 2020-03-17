#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :repo, "The repo to update. If not passed, will try all repos in config/repos.yml", :type => :strings
  opt :title, "The new milestone title", :type => :string, :required => true
  opt :dry_run, "", :default => false
end

ManageIQ::Release.each_repo(opts[:repo]) do |repo|
  ManageIQ::Release::ReleaseMilestone.new(repo, opts.slice(:title, :dry_run)).run
end
