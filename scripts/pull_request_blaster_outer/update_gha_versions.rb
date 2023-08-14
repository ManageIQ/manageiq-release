#! /usr/bin/env ruby

ACTIONS_VERSIONS = {
  "actions/checkout"                => "v3",
  "actions/setup-go"                => "v4",
  "actions/setup-node"              => "v3",
  "paambaati/codeclimate-action"    => "v5",
  "peter-evans/create-pull-request" => "v5",
  "peter-evans/repository-dispatch" => "v2",
  "ruby/setup-ruby"                 => "v1"
}.freeze

IMAGE_VERSIONS = {
  "manageiq/memcached"  => "1.5",
  "manageiq/postgresql" => "13"
}.freeze

files = Dir.glob(".github/workflows/*.yaml") + Dir.glob("lib/generators/manageiq/plugin/templates/.github/workflows/*.yaml")
files.sort.each do |f|
  contents = File.read(f)

  ACTIONS_VERSIONS.each do |action, version|
    contents.gsub!(/uses: #{action}@.+/, "uses: #{action}@#{version}")
  end

  IMAGE_VERSIONS.each do |image, version|
    contents.gsub!(/image: #{image}:.+/, "image: #{image}:#{version}")
  end

  File.write(f, contents)
end
