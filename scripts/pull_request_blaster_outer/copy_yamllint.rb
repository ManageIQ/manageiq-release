#! /usr/bin/env ruby

require 'open-uri'
contents = open("https://raw.githubusercontent.com/ManageIQ/manageiq/master/lib/generators/provider/templates/.yamllint", &:read)
File.write(File.join(Dir.pwd, ".yamllint"), contents)
