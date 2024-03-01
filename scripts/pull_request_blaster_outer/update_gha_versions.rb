#! /usr/bin/env ruby

ACTIONS_VERSIONS = {
  "actions/checkout"                => "v4",
  "actions/setup-go"                => "v5",
  "actions/setup-node"              => "v4",
  "github/codeql-action/analyze"    => "v3",
  "github/codeql-action/init"       => "v3",
  "paambaati/codeclimate-action"    => "v5",
  "peter-evans/create-pull-request" => "v6",
  "peter-evans/repository-dispatch" => "v3",
  "ruby/setup-ruby"                 => "v1"
}.freeze

IMAGE_VERSIONS = {
  "manageiq/memcached"  => "1.5",
  "manageiq/postgresql" => "13"
}.freeze

files = Dir.glob(".github/workflows/*.y*ml") + Dir.glob("lib/generators/manageiq/plugin/templates/.github/workflows/*.y*ml")
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
