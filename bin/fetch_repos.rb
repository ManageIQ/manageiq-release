#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'trollop'

opts = Trollop.options do
  opt :branch,   "The target branch",           :type => :string,  :required => false
  opt :checkout, "Also checkout target branch", :type => :boolean, :default => false
end

repos = opts[:branch] ? ManageIQ::Release::Repos[opts[:branch]] : ManageIQ::Release::Repos.all_repos
repos.each do |repo|
  puts ManageIQ::Release.header(repo.name)
  repo.fetch
  Dir.chdir(repo.path) do
    repo.checkout(opts[:branch])
  end if opts[:checkout] && opts[:branch] && !repo.options["has_real_releases"]
  puts
end
