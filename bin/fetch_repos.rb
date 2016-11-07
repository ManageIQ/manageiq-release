#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'

ManageIQ::Release::Repos.all_repos.each do |repo|
  puts ManageIQ::Release.header(repo.name)
  repo.fetch
  puts
end
