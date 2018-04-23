#! /usr/bin/env ruby

# assume manageiq is the sibling directory of manageiq-release
#

require 'fileutils'
require 'pathname'

pwd = Pathname.new(Dir.pwd)
lint = pwd.join(*%w{.. manageiq lib generators provider templates .yamllint})
FileUtils.cp(lint, pwd.join(".yamllint")) unless File.exist?(pwd.join(".yamllint"))
