#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  ManageIQ::Release.common_options(self, :repo_set_default => nil)
end
opts[:repo] = ManageIQ::Release::Labels.all.keys.sort unless opts[:repo] || opts[:repo_set]

ManageIQ::Release.each_repo(opts) do |repo|
  ManageIQ::Release::UpdateLabels.new(repo.github_repo, opts).run
end
