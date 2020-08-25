#! /usr/bin/env ruby

expected_env_vars = %w[GITHUB_API_TOKEN CODECLIMATE_API_TOKEN GITHUB_REPO]
missing = expected_env_vars.reject { |k| ENV.key?(k) }
if missing.any?
  puts "ERROR: Expected the following env vars set:\n\t#{missing.join("\n\t")}"
  exit 1
end

$: << File.expand_path("../../lib", __dir__)
require "manageiq-release"

repo = ManageIQ::Release::Repo.new(ENV["GITHUB_REPO"])
opts = {:dry_run => ENV["DRY_RUN"]}

readme = ManageIQ::Release::ReadmeBadges.new(repo, opts)
travis = ManageIQ::Release::Travis.new(repo, opts)
code_climate = ManageIQ::Release::CodeClimate.new(repo, opts)

puts "\n** Enabling Travis..."
travis.enable
puts "\n** Enabling CodeClimate..."
code_climate.enable
puts "\n** Enabling Travis / CodeClimate test reporter integration..."
code_climate.set_travis_test_reporter_id

puts "\n** Updating README.md for CodeClimate badges..."
b = readme.badges.detect { |b| b["description"] == ManageIQ::Release::CodeClimate.badge_name }
b.update(code_climate.badge_details)
b = readme.badges.detect { |b| b["description"] == ManageIQ::Release::CodeClimate.coverage_badge_name }
b.update(code_climate.coverage_badge_details)
readme.save!

puts "\n** Sending Pull Request..."
