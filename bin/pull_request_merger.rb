#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :prs,      "The list of PRs to merge",           :type => :strings, :required => true
  opt :assignee, "GitHub user to assign when merging", :type => :string,  :required => true
  opt :labels,   "Labels to apply when merging",       :type => :strings

  ManageIQ::Release.common_options(self)
end

# TODO: Normalize any PR format (perhaps pull out of miq-bot or cross-repo-tests)
PR_REGEX = %r{^([^/#]+/[^/#]+)#([^/#]+)$}
Optimist.die :prs, "must be in the form `org/repo#pr`" unless opts[:prs].all? { |pr| pr.match?(PR_REGEX) }

def merge_pull_request(github_repo, pr_number, dry_run:, **_)
  if dry_run
    puts "** dry-run: github.merge_pull_request(#{github_repo.inspect}, #{pr_number.inspect})"
  else
    ManageIQ::Release.github.merge_pull_request(github_repo, pr_number)
  end
end

def add_labels(github_repo, pr_number, labels:, dry_run:, **_)
  labels = Array(labels)
  if dry_run
    puts "** dry_run: github.add_labels_to_an_issue(#{github_repo.inspect}, #{pr_number.inspect}, #{labels.inspect})"
  else
    ManageIQ::Release.github.add_labels_to_an_issue(github_repo, pr_number, labels)
  end
end

def assign_user(github_repo, pr_number, assignee:, dry_run:, **_)
  assignee = assignee[1..] if assignee.start_with?("@")
  if dry_run
    puts "** dry_run: github.update_issue(#{github_repo.inspect}, #{pr_number.inspect}, \"assignee\" => #{assignee.inspect})"
  else
    ManageIQ::Release.github.update_issue(github_repo, pr_number, "assignee" => assignee)
  end
end

opts[:prs].each do |pr|
  puts ManageIQ::Release.header(pr)

  github_repo, pr_number = PR_REGEX.match(pr).captures

  merge_pull_request(github_repo, pr_number, opts)
  add_labels(github_repo, pr_number, opts) if opts[:labels].present?
  assign_user(github_repo, pr_number, opts)

  puts
end
