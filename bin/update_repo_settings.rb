#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  ManageIQ::Release.common_options(self)
end

ManageIQ::Release.each_repo(opts) do |repo|
  ManageIQ::Release::UpdateRepoSettings.new(repo.github_repo, opts).run
end
