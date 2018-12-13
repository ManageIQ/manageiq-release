#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :base,    "The name of the branch you want the changes pulled into.",   :type => :string, :required => true
  opt :head,    "The name of the branch containing the changes.",             :type => :string, :required => true
  opt :script,  "The path to the script that will update the desired files.", :type => :string, :required => true
  opt :message, "The commit message and PR title for this change.",           :type => :string, :required => true

  opt :body,      "The Pull Request body (optional).",                        :type => :string
  opt :body_file, "The Pull Request body, read from file (optional).",        :type => :string, :short    => 'f'
  opt :assign,    "GH user (no @) to assign to the pull requests (optional)", :type => :string
  opt :labels,    "Labels to add to the PR (optional, comma delimited).",     :type => :strings

  opt :repo,    "The repo to update. If not passed, will try all repos in config/repos.yml.", :type => :strings
  opt :dry_run, "Make local changes, but don't fork, push, or create the pull request.", :default => false
end

ManageIQ::Release::PullRequestBlasterOuter.run opts
