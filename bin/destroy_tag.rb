#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'trollop'

opts = Trollop.options do
  opt :tag,    "The tag name",      :type => :string, :required => true
  opt :branch, "The target branch", :type => :string, :required => true
end

repos = ManageIQ::Release::Repos[opts[:branch]]
repos.each do |repo|
  puts ManageIQ::Release.header("Untagging #{repo.name}")
  ManageIQ::Release::DestroyTag.new(repo, opts[:tag]).run
  puts
end
