#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :tag,    "The new tag name.",       :type => :string, :required => true
  opt :branch, "The branch to tag from.", :type => :string
  opt :skip,   "The repo(s) to skip.",    :type => :strings

  ManageIQ::Release.common_options(self, :repo_set_default => nil)
end
opts[:branch] ||= opts[:tag].split("-").first
opts[:repo_set] = opts[:branch] unless opts[:repo] || opts[:repo_set]

review = StringIO.new
post_review = StringIO.new

# Move manageiq repo to the end of the list.  The rake release script on manageiq
#   depends on all of the other repos running their rake release scripts first.
repos = ManageIQ::Release.repos_for(opts)
repos = repos.partition { |r| r.github_repo != "ManageIQ/manageiq" }.flatten

# However, the other plugins require that manageiq is at the right checkout in
#   order to run their rake release scripts
manageiq_repo = repos.last
puts ManageIQ::Release.header("Checking out #{manageiq_repo.name}")
manageiq_repo.fetch
manageiq_repo.checkout(opts[:branch])

repos.each do |repo|
  next if Array(opts[:skip]).include?(repo.name)
  next if repo.options.has_real_releases || repo.options.skip_tag

  release_tag = ManageIQ::Release::ReleaseTag.new(repo, opts)

  puts ManageIQ::Release.header("Tagging #{repo.name}")
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
