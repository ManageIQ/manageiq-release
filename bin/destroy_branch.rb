#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :branch, "The target branch", :type => :string, :required => true
end

repos = ManageIQ::Release::Repos["master"]
repos.each do |repo|
  puts ManageIQ::Release.header("Destroying #{repo.name}")

  repo.chdir do
    system("git checkout master")
    system("git branch -D #{opts[:branch]}")
  end
end
