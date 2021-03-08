#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :branch,  "The target branch to backport to.", :type => :string, :required => true

  opt :skip,    "The repo(s) to skip.",              :type => :strings

  ManageIQ::Release.common_options(self, :repo_set_default => nil)
end
branch = opts[:branch]
opts[:repo_set] = branch unless opts[:repo] || opts[:repo_set]

repos = ManageIQ::Release.repos_for(opts)
if opts[:skip]&.any?
  to_skip = opts[:skip].map { |r| ManageIQ::Release.repo_for(s).github_repo }.to_set
  repos.reject! { |r| to_skip.include?(r.github_repo) }
end

repos = repos.index_by(&:github_repo)

ManageIQ::Release::BackportPrs.search(branch, repos.keys).each do |github_repo, prs|
  puts ManageIQ::Release.header(github_repo)

  repo = repos[github_repo]
  ManageIQ::Release::BackportPrs.new(repo, opts.merge(:prs => prs)).run
end
