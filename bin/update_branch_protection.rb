#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :branch, "The branch to protect.", :type => :string, :required => true

  ManageIQ::Release.common_options(self, :repo_set_default => nil)
end
opts[:repo_set] = opts[:branch] unless opts[:repo] || opts[:repo_set]

ManageIQ::Release.repos_for(opts).each do |repo|
  next if opts[:branch] != "master" && repo.options.has_real_releases

  puts ManageIQ::Release.header(repo.name)
  ManageIQ::Release::UpdateBranchProtection.new(repo.github_repo, opts).run
  puts
end
