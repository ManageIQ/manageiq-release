#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'trollop'

opts = Trollop.options do
  opt :branch, "The target branch", :type => :string, :required => false
end

repos = opts[:branch] ? ManageIQ::Release::Repos[opts[:branch]] : ManageIQ::Release::Repos.all_repos
repos.each do |repo|
  puts ManageIQ::Release.header(repo.name)
  repo.fetch
  puts
end
