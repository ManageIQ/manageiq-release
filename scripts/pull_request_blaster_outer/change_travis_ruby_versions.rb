#! /usr/bin/env ruby

versions = ENV["VERSIONS"].to_s.split(",").map(&:strip)
if versions.empty? || versions.any? { |v| v !~ /^\d+\.\d+\.\d+$/ }
  puts "ERROR: VERSIONS env var must be set to a comma separated list of version numbers"
  exit 1
end

travis = File.join(Dir.pwd, ".travis.yml")
unless File.exist?(travis)
  puts "#{travis} doesn't exist, skipping"
  exit 0
end

travis_content = File.read(travis)

changed = false
versions.each do |version|
  major_minor = version.split(".")[0, 2].join(".")
  changed = true if travis_content.gsub!(/#{major_minor}\.[0-9]+/, version)
end

if changed
  File.write(travis, travis_content)
  puts "Wrote updated travis.yml at: #{travis}"
end
