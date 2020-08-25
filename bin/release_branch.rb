#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :branch, "The new branch name.", :type => :string, :required => true

  ManageIQ::Release.common_options(self, :except => :dry_run) # TODO: Implement dry_run
end

review = StringIO.new
post_review = StringIO.new

ManageIQ::Release.repos_for(opts).each do |repo|
  next if repo.options.has_real_releases

  release_branch = ManageIQ::Release::ReleaseBranch.new(repo, opts)

  puts ManageIQ::Release.header("Branching #{repo.name}")
  release_branch.run
  puts

  review.puts ManageIQ::Release.header(repo.name)
  review.puts release_branch.review
  review.puts
  post_review.puts release_branch.post_review
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
