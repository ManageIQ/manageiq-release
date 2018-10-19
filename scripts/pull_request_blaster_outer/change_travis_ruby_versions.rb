#! /usr/bin/env ruby

versions = ENV["VERSIONS"].to_s.split(",").map(&:strip)
if versions.empty? || versions.any? { |v| v !~ /^\d\.\d\.\d$/ }
  puts "ERROR: VERSIONS env var must be set to a comma separated list of version numbers"
  exit 1
end

travis = File.join(Dir.pwd, ".travis.yml")
unless File.exist?(travis)
  puts "#{travis} doesn't exist, skipping"
  exit 1
end

require 'yaml'
yml = YAML.load_file(travis)
unless yml.key?("rvm")
  puts "#{travis} doesn't have rvm key, skipping"
  exit 1
end

yml["rvm"] = versions

File.write(travis, yml.to_yaml.sub("---\n", ""))
