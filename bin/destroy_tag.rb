#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :tag,    "The tag name",      :type => :string, :required => true
  opt :branch, "The target branch", :type => :string, :required => true
end

tag = opts[:tag]
post_review = StringIO.new

repos = ManageIQ::Release::Repos[opts[:branch]]
repos.each do |repo|
  puts ManageIQ::Release.header("Untagging #{repo.name}")
  destroy_tag = ManageIQ::Release::DestroyTag.new(repo, tag)
  destroy_tag.run
  post_review.puts(destroy_tag.post_review)
  puts
end

puts
puts "Run the following script to delete '#{tag}' tag from all repos"
puts
puts post_review.string
