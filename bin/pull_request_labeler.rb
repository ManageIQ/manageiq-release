#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :prs,    "The list of PRs to merge", :type => :strings, :required => true
  opt :labels, "Labels to apply",          :type => :strings, :required => true

  ManageIQ::Release.common_options(self)
end

# TODO: Normalize any PR format (perhaps pull out of miq-bot or cross-repo-tests)
PR_REGEX = %r{^([^/#]+/[^/#]+)#([^/#]+)$}
Optimist.die :prs, "must be in the form `org/repo#pr`" unless opts[:prs].all? { |pr| pr.match?(PR_REGEX) }

def add_labels(github_repo, pr_number, labels:, dry_run:, **_)
  labels = Array(labels)
  if dry_run
    puts "** dry_run: github.add_labels_to_an_issue(#{github_repo.inspect}, #{pr_number.inspect}, #{labels.inspect})"
  else
    ManageIQ::Release.github.add_labels_to_an_issue(github_repo, pr_number, labels)
  end
end

opts[:prs].each do |pr|
  puts ManageIQ::Release.header(pr)

  github_repo, pr_number = PR_REGEX.match(pr).captures
  add_labels(github_repo, pr_number, opts)

  puts
end
