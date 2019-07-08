#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :repo_set, "The repo set", :type => :string,  :required => true
  opt :dry_run,  "",             :default => true
end

ManageIQ::Release::Repos[opts[:repo_set]].each do |repo|
  puts ManageIQ::Release.header(repo.name)
  repo.fetch
  Dir.chdir(repo.path) do
    repo.checkout("stable", "origin/stable")
    repo.git.merge("--no-ff", "--no-edit", "origin/master")

    if opts[:dry_run]
      puts "** dry-run: git push origin stable"
    else
      repo.git.push("origin", "stable")
    end
  end
  puts
end

