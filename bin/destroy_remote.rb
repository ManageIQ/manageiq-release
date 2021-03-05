#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :remote, "The remote to destroy", :type => :string, :required => true

  ManageIQ::Release.common_options(self)
end

ManageIQ::Release.each_repo(opts) do |repo|
  next unless repo.remote?(opts[:remote])

  if opts[:dry_run]
    puts "** dry-run: git rm #{opts[:remote]}"
  else
    repo.git.remote("rm", opts[:remote])
  end
end
