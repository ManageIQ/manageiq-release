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
readme.badges.clear

travis = ManageIQ::Release::Travis.new(repo, opts)
puts "Enabling Travis..."
travis.enable
travis.set_env("DEPLOY_REPO", ENV["DEPLOY_REPO"]) if ENV["DEPLOY_REPO"]
puts "Creating .travis.yml file..."
travis.init_yaml(language: "node_js")
travis.add_codeclimate!
travis.add_deploy!(ENV["DEPLOY_REPO"], ENV["DEPLOY_SSH_KEY"]) if ENV["DEPLOY_REPO"]
travis.save!
puts "Modifying README.md for Travis Build Status..."
readme.badges << travis.badge_details

code_climate = ManageIQ::Release::CodeClimate.new(repo, opts)
puts "Enabling CodeClimate..."
code_climate.enable
puts "Modifying README.md for CodeClimate Maintainability..."
readme.badges << code_climate.badge_details
puts "Modifying README.md for CodeClimate Test Coverage..."
readme.badges << code_climate.coverage_badge_details
puts "Enabling Travis / CodeClimate test reporter integration..."
code_climate.set_travis_test_reporter_id
puts "Writing CodeClimate and RuboCop files..."
code_climate.save!

puts "Saving README.md..."
readme.save!

puts "Saving LICENSE.txt..."
license = ManageIQ::Release::License.new(repo, opts)
license.license = "apache-2.0"
license.save!
