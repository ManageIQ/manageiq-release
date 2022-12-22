#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :branch,        "The new branch name.",                                   :type => :string, :required => true
  opt :next_branch,   "The next branch name.",                                  :type => :string, :required => true
  opt :source_branch, "The source branch from which to create the new branch.", :default => "master"

  ManageIQ::Release.common_options(self, :repo_set_default => nil)
end
opts[:repo_set] = opts[:branch] unless opts[:repo] || opts[:repo_set]

repos = ManageIQ::Release.repos_for(**opts)
Optimist.die(:branch, "not found in config/repos*.yml") if repos.nil?

Optimist.die(:branch, "not found in config/labels.yml") unless ManageIQ::Release::Labels.config.key?("release_#{opts[:branch]}")

review = StringIO.new
post_review = StringIO.new

repos.each do |repo|
  next if repo.options.has_real_releases

  release_branch = ManageIQ::Release::ReleaseBranch.new(repo, **opts)

  puts ManageIQ::Release.header("Branching #{repo.name}")
  release_branch.run
  puts

  review.puts ManageIQ::Release.header(repo.name)
  review.puts release_branch.review
  review.puts

  post_msg = release_branch.post_review
  post_review.puts post_msg if post_msg
end

puts
puts ManageIQ::Release.separator
puts
puts "Review the following:"
puts
puts review.string
puts
puts "If all changes are correct,"
puts "  run the following script to push all of the new branches"
puts
puts post_review.string
puts
puts "Once completed, be sure to follow the rest of the release checklist."
