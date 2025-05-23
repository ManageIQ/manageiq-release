#! /usr/bin/env ruby
require "rubygems"
versions = ENV["VERSIONS"].to_s.split(",").map(&:strip)
if versions.empty? || versions.any? { |v| v !~ /^\d+\.\d+$/ }
  puts "ERROR: VERSIONS env var must be set to a comma separated list of version numbers such as:"
  puts "VERSIONS=\"3.1,3.3\" GITHUB_API_TOKEN=XXX bin/pull_request_blaster_outer.rb --base master --head update_ci_rubies --script scripts/pull_request_blaster_outer/change_ci_ruby_versions.rb --message \"Test ruby 3.1 and 3.3\""
  exit 1
end

ci = File.join(Dir.pwd, ".github", "workflows", "ci.yaml")
unless File.exist?(ci)
  puts "#{ci} doesn't exist, skipping"
  exit 0
end

sorted_versions = versions.sort {|x, y| Gem::Version.new(x) <=> Gem::Version.new(y)}

changed = false

require "yaml"
yaml = YAML.load_file(ci)

require "more_core_extensions/core_ext/hash"
if yaml.fetch_path("jobs", "ci", "strategy", "matrix", "ruby-version") && yaml.fetch_path("jobs", "ci", "strategy", "matrix", "ruby-version") != sorted_versions
  yaml["jobs"]["ci"]["strategy"]["matrix"]["ruby-version"] = sorted_versions
  changed = true
end

includes = yaml.fetch_path("jobs", "ci", "strategy", "matrix", "include")
if includes.kind_of?(Array)
  yaml["jobs"]["ci"]["strategy"]["matrix"]["include"].delete_if { |include| !sorted_versions.include?(include["ruby-version"]) && changed = true }
  if yaml["jobs"]["ci"]["strategy"]["matrix"]["include"].empty?
    yaml["jobs"]["ci"]["strategy"]["matrix"].delete("include")
    changed = true
  end
end

if changed
  ci_yaml = YAML.dump(yaml)
  ci_yaml.gsub!(/^true:/, "on:") # YAML replaces on: with true:

  File.write(ci, ci_yaml)
  puts "Wrote updated ci.yaml at: #{ci}"
end
