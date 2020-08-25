#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :tag, "The tag to destroy", :type => :string, :required => true

  ManageIQ::Release.common_options(self, :except => :dry_run, :repo_set_default => nil)
end
opts[:repo_set] = opts[:tag].split("-").first unless opts[:repo] || opts[:repo_set]

post_review = StringIO.new

ManageIQ::Release.each_repo(opts) do |repo|
  destroy_tag = ManageIQ::Release::DestroyTag.new(repo, opts)
  destroy_tag.run
  post_review.puts(destroy_tag.post_review)
end

puts
puts "Run the following script to delete '#{opts[:tag]}' tag from all remote repos"
puts
puts post_review.string
