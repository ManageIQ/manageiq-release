#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'

puts [ManageIQ::Release.github.rate_limit.to_h].tableize
