#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'

success = ManageIQ::Release::GitMirror.new.mirror_all
exit 1 unless success
