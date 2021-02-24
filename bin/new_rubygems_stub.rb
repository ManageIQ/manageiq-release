#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :owners, "Owners to add to the gem stub", :type => :strings, :default => []

  ManageIQ::Release.common_options(self, :except => :repo_set)
end

ManageIQ::Release.each_repo(opts) do |repo|
  ManageIQ::Release::RubygemsStub.new(repo.name, opts).run
end
