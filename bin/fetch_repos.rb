#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :branch,   "The branch to fetch.",                   :type => :string,  :required => true
  opt :checkout, "Checkout target branch after fetching.", :type => :boolean, :default => false

  ManageIQ::Release.common_options(self, :except => :dry_run, :repo_set_default => nil)
end
opts[:repo_set] = opts[:branch] unless opts[:repo] || opts[:repo_set]

ManageIQ::Release.each_repo(opts) do |repo|
  repo.fetch
  repo.checkout(opts[:branch]) if opts[:checkout] && opts[:branch] && !repo.options.has_real_releases
end
