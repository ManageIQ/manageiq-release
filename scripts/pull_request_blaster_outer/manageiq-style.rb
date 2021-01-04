#! /usr/bin/env ruby

require 'bundler/setup'
require 'manageiq-style'

ManageIQ::Style::CLI.new(:install => true).run
