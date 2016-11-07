#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'

ManageIQ::Release::Repos.all_repos.each do |repo|
  ManageIQ::Release.log_header(repo.name)
  repo.fetch
  puts
end
