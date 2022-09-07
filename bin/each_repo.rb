#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :command, "A command to run in each repo", :type => :string, :required => true
  opt :ref,     "Ref to checkout before running the command", :type => :string, :default => "master"

  opt :skip,    "The repos to skip", :type => :strings, :default => []

  ManageIQ::Release.common_options(self, :except => :dry_run)
end

ManageIQ::Release.each_repo(**opts) do |r|
  next if opts[:skip].include?(r.github_repo)

  begin
    r.fetch
    r.checkout(opts[:ref])
  rescue MiniGit::GitError
    next
  end

  r.chdir do
    puts "+ #{opts[:command]}"
    system(opts[:command])
  end
end
