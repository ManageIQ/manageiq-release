#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'travis'
require 'travis/pro/auto_login'
require 'optimist'

opts = Optimist.options do
  opt :ref, "The branch or release tag to rebuild.", :type => :string, :required => true

  ManageIQ::Release.common_options(self, :except => :dry_run, :repo_set_default => nil)
end
opts[:repo_set] = opts[:ref].split("-").first unless opts[:repo] || opts[:repo_set]

puts "Restarting Travis builds for #{opts[:ref]}:"

ManageIQ::Release.repos_for(**opts).collect do |repo|
  next if repo.options.has_real_releases

  repo = Travis::Pro::Repository.find(repo.github_repo)
  begin
    last_build = repo.last_on_branch(opts[:ref])
  rescue Travis::Client::NotFound
    # Ignore repo which doesn't have Travis enabled for that branch
    next
  end

  puts "- #{repo.name}..."
  last_build.restart
end
