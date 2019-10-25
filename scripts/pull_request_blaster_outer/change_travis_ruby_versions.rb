#! /usr/bin/env ruby
require "rubygems"
versions = ENV["VERSIONS"].to_s.split(",").map(&:strip)
if versions.empty? || versions.any? { |v| v !~ /^\d+\.\d+\.\d+$/ }
  puts "ERROR: VERSIONS env var must be set to a comma separated list of version numbers such as:"
  puts "VERSIONS=\"2.5.7,2.6.5\" GITHUB_API_TOKEN=XXX bin/pull_request_blaster_outer.rb --base master --head update_travis_rubies --script scripts/pull_request_blaster_outer/change_travis_ruby_versions.rb --message \"Test ruby 2.5.7/2.6.5, see: ManageIQ/manageiq#19414\""
  exit 1
end

travis = File.join(Dir.pwd, ".travis.yml")
unless File.exist?(travis)
  puts "#{travis} doesn't exist, skipping"
  exit 0
end

sorted_versions = versions.sort {|x, y| Gem::Version.new(x) <=> Gem::Version.new(y)}

changed = false

require "yaml"
yaml = YAML.load_file(travis)

if yaml["rvm"] && yaml["rvm"] != sorted_versions
  yaml["rvm"] = sorted_versions
  changed = true
end

excludes = yaml["matrix"]["exclude"] if yaml["matrix"]
if excludes.kind_of?(Array)
  excludes.each do |exclude|
    if exclude["rvm"] && exclude["rvm"] != sorted_versions.first
      exclude["rvm"] = sorted_versions.first
      changed = true
    end
  end
end

if changed
  File.write(travis, YAML.dump(yaml))
  puts "Wrote updated travis.yml at: #{travis}"
end
