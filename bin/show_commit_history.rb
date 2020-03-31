#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :from,   "The commit log 'from' ref", :type => :string,  :required => true
  opt :to,     "The commit log 'to' ref" ,  :type => :string,  :required => true
  opt :branch, "The target branch",         :type => :string,  :required => true
  opt :skip,   "The repos to skip",         :type => :strings, :default => ["manageiq_docs"]
end

from_version = opts[:from]
to_version   = opts[:to]
range        = "#{from_version}..#{to_version}"
skip_repos   = opts[:skip]

puts "Git commit log between #{from_version} and #{to_version}\n\n"

repos = ManageIQ::Release::Repos[opts[:branch]]
repos.each do |repo|
  next if repo.options["has_real_releases"]
  next if skip_repos.include?(repo.name)
  repo.fetch(output: false)
  puts ManageIQ::Release.header(repo.name)
  repo.git.log({:oneline => true, :decorate => true, :reverse => true}, range)
  puts "\n\n"
end
