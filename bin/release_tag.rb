#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'trollop'

opts = Trollop.options do
  opt :tag,    "The new tag name",  :type => :string, :required => true
  opt :branch, "The target branch", :type => :string, :required => true
end

repos = ManageIQ::Release::Repos[opts[:branch]]
review = StringIO.new
post_review = StringIO.new

repos.each do |repo|
  puts ManageIQ::Release.header("Tagging #{repo.name}")
  release_tag = ManageIQ::Release::ReleaseTag.new(repo, opts[:branch], opts[:tag])
  release_tag.run
  puts

  review.puts ManageIQ::Release.header(repo.name)
  review.puts release_tag.review
  review.puts
  post_review.puts release_tag.post_review
end

puts
puts ManageIQ::Release.separator
puts
puts "Review the following:"
puts
puts review.string
puts
puts "If the tags are all correct,"
puts "  run the following script to push all of the new tags"
puts
puts post_review.string
puts
