#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :labels, "The labels to delete.", :type => :strings, :required => true

  ManageIQ::Release.common_options(self, :repo_set_default => nil)
end
opts[:repo] = ManageIQ::Release::Labels.all.keys.sort unless opts[:repo] || opts[:repo_set]

def delete(repo, label, dry_run:, **_)
  puts "Deleting #{label.inspect}"

  if dry_run
    puts "** dry-run: github.delete_label!(#{repo.inspect}, #{label.inspect})"
  else
    ManageIQ::Release.github.delete_label!(repo, label)
  end
end

ManageIQ::Release.each_repo(opts) do |repo|
  opts[:labels].each do |label|
    delete(repo.github_repo, label, opts)
  end
end
