#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :branch,  "The target branch",:type => :string,  :required => false
  opt :dry_run, "",                 :type => :boolean, :default => true
end

ManageIQ::Release::Internationalization.new(opts.slice(:branch, :dry_run)).update_pot
