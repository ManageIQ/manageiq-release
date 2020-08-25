#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  ManageIQ::Release.common_options(self)
end

ManageIQ::Release.each_repo(opts) do |repo|
  repo.fetch
  repo.chdir do
    repo.checkout("stable", "origin/stable")
    repo.git.merge("--no-ff", "--no-edit", "origin/master")

    if opts[:dry_run]
      puts "** dry-run: git push origin stable"
    else
      repo.git.push("origin", "stable")
    end
  end
end

