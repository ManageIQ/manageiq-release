#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :from, "The commit log 'from' ref", :type => :string,  :required => true
  opt :to,   "The commit log 'to' ref" ,  :type => :string,  :required => true
  opt :skip, "The repos to skip",         :type => :strings, :default => ["manageiq-documentation"]

  ManageIQ::Release.common_options(self, :except => :dry_run)
end

range = "#{opts[:from]}..#{opts[:to]}"

puts "Git commit log between #{opts[:from]} and #{opts[:to]}\n\n"

ManageIQ::Release.repos_for(opts).each do |repo|
  next if repo.options.has_real_releases
  next if opts[:skip].include?(repo.name)

  puts ManageIQ::Release.header(repo.name)
  repo.fetch(output: false)
  repo.git.log({:oneline => true, :decorate => true, :reverse => true}, range)
  puts "\n\n"
end
