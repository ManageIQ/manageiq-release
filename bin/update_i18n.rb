#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :branch,  "The target branch",:type => :string,  :required => false

  ManageIQ::Release.common_options(self, :only => :dry_run)
end

ManageIQ::Release::Internationalization.new(**opts).update_message_catalogs
