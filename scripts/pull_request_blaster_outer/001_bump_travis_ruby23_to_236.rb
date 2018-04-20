#! /usr/bin/env ruby

# We're run from the repo's directory
require 'yaml'

travis = "#{Dir.pwd}/.travis.yml"

unless File.exist?(travis)
  puts "#{travis} doesn't exist, skipping"
  exit 1
end

yml = YAML.load_file(travis)
unless yml.key?("rvm")
  puts "#{travis} doesn't have rvm key, skipping"
  exit 1
end

yml["rvm"].reject! {|r| r.start_with?("2.3")}
yml["rvm"].unshift("2.3.6")

File.open(travis, 'w') do |file|
  file.write(YAML.dump(yml).sub("---\n", ""))
end
