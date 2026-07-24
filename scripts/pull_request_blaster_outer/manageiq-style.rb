#! /usr/bin/env ruby

require 'bundler/inline'
gemfile do
  gem 'manageiq-style', '>=1.5.0'
  gem 'multi_repo',     '>=0.3.1'
  gem 'colorize'
end

gemfile = Dir.glob("Gemfile").first
gemfile_ref = gemfile && File.read(gemfile).include?("manageiq-style")
gemspec = Dir.glob("*.gemspec").first
gemspec_ref = gemspec && File.read(gemspec).include?("manageiq-style")

if File.exist?(".codeclimate.yml") && (gemfile_ref || gemspec_ref)
  ManageIQ::Style::CLI.new(:install => true, :yamllint => false, :hamllint => false).run
else
  puts "!! Skipping since .codeclimate.yml was not found".light_yellow
end
