#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'manageiq/release/rackspace_files_sync'

require 'optimist'

opts = Optimist.options do
  opt :destination, "Destination bucket name", :type => :string, :required => true
  opt :source, "Source folder name", :type => :string, :required => true

  opt :delete, "Delete extre files in the bucket", :type => :string
end

ManageIQ::Release::RackspaceFilesSync.new(opts).sync
