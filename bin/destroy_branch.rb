#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :branch, "The branch to destroy.", :type => :string, :required => true

  ManageIQ::Release.common_options(self, :except => :dry_run)
end

ManageIQ::Release.each_repo(opts) do |repo|
  repo.chdir do
    system("git checkout master")
    system("git branch -D #{opts[:branch]}")
  end
end
