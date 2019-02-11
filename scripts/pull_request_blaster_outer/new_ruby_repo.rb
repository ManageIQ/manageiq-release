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
puts "Creating .travis.yml file..."
travis.init_yaml(language: "ruby")
travis.add_codeclimate!
travis.add_postgres!(production_db: "#{ENV["GITHUB_REPO"].split("/").last.gsub("-", "_")}_production")
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

hakiri = ManageIQ::Release::Hakiri.new(repo, opts)
puts "Modifying README.md for Hakiri..."
readme.badges << hakiri.badge_details

puts "Saving README.md..."
readme.save!

puts "Saving LICENSE.txt..."
license = ManageIQ::Release::License.new(repo, opts)
license.license = "apache-2.0"
license.save!


require "securerandom"
deploy_token = ENV["DEPLOY_TOKEN"] || SecureRandom.hex(40)

hook = ManageIQ::Release.github.hooks(ENV["GITHUB_REPO"]).detect { |h| h.config.url.include?("openshift.com") }
hook ||= ManageIQ::Release.github.create_hook(ENV["GITHUB_REPO"], "web", {
  :url          => "https://api.insights-dev.openshift.com/oapi/v1/namespaces/buildfactory/buildconfigs/#{ENV["GITHUB_REPO"].split("/").last.tr("_", "-")}/webhooks/#{}/github",
  :content_type => "json"
})

#
# Test setup
#

test_file = %w[spec/rails_helper.rb spec/spec_helper.rb].detect { |f| File.exist?(f) }
if test_file
  puts "Modifying #{test_file} for Test Coverage..."
  test_file = File.read(test_file)
  unless test_file.include?("simplecov")
    test_file.insert(0, <<~EOF)
      if ENV['CI']
        require 'simplecov'
        SimpleCov.start
      end

    EOF
  end
end
