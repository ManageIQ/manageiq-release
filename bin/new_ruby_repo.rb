#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'trollop'

opts = Trollop.options do
  opt :repo, "The repo to update.", :required => true, :type => :strings

  opt :dry_run, "", :default => false
end

ManageIQ::Release.each_repo(opts[:repo]) do |repo|
  ManageIQ::Release::UpdateRepoSettings.new(repo.github_repo, opts.slice(:dry_run)).run
  ManageIQ::Release::UpdateBranchProtection.new(repo.github_repo, opts.slice(:dry_run).merge(:branch => "master")).run
  ManageIQ::Release::PullRequestBlasterOuter.new(repo, opts.slice(:dry_run).merge(
    :base    => "master",
    :head    => "new_ruby_repo",
    :script  => "scripts/pull_request_blaster_outer/new_ruby_repo.rb",
    :message => "Prepare initial third party services"
  )).blast

  puts
  puts "***** MANUAL THINGS *******"
  puts "Go to https://codeclimate.com/github/#{repo.github_repo} => settings => GitHub => Pull Request Status Updates => Install"
  puts "Enable hakiri"
  puts "Add repo to the bot"
end

