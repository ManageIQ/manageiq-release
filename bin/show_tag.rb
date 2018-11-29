#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'more_core_extensions/core_ext/array/tableize'
require 'optimist'

opts = Optimist.options do
  opt :tag,    "The tag name",      :type => :string, :required => true
  opt :branch, "The target branch", :type => :string, :required => true
end

HEADER = %w(Repo SHA Message).freeze

def show_tag(repo, tag)
  line = repo.git.capturing.show({:summary => true, :oneline => true}, tag)
  sha, message = line.split(" ", 2)
  [repo.name, sha, message]
end

repos = ManageIQ::Release::Repos[opts[:branch]]
table = [HEADER] + repos.collect { |repo| show_tag(repo, opts[:tag]) }
puts table.tableize(:max_width => 75)
