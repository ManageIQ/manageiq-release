#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :prs,    "The list of PRs to merge", :type => :strings, :required => true
  opt :add,    "Labels to add",            :type => :strings, :required => true
  opt :remove, "Labels to remove",         :type => :strings, :required => true

  ManageIQ::Release.common_options(self, :only => :dry_run)
end

# TODO: Normalize any PR format (perhaps pull out of miq-bot or cross-repo-tests)
PR_REGEX = %r{^([^/#]+/[^/#]+)#([^/#]+)$}
Optimist.die :prs, "must be in the form `org/repo#pr`" unless opts[:prs].all? { |pr| pr.match?(PR_REGEX) }

def github
  ManageIQ::Release.github
end

def add_labels(github_repo, pr_number, labels:, dry_run:, **_)
  labels = Array(labels)
  if dry_run
    puts "** dry_run: github.add_labels_to_an_issue(#{github_repo.inspect}, #{pr_number.inspect}, #{labels.inspect})"
  else
    github.add_labels_to_an_issue(github_repo, pr_number, labels)
  end
end

def remove_labels(github_repo, pr_number, labels:, dry_run:, **_)
  Array(labels).each do |label|
    remove_label(github_repo, pr_number, label: label, dry_run: dry_run)
  end
end

def remove_label(github_repo, pr_number, label:, dry_run:, **_)
  if dry_run
    puts "** dry_run: github.remove_label(#{github_repo.inspect}, #{pr_number.inspect}, #{label.inspect})"
  else
    github.remove_label(github_repo, pr_number, label)
  end
rescue Octokit::NotFound
  # Ignore labels that are not found, because we want them removed anyway
end

opts[:prs].each do |pr|
  puts ManageIQ::Release.header(pr)

  github_repo, pr_number = PR_REGEX.match(pr).captures

  add_labels(github_repo, pr_number, labels: opts[:add], **opts)
  remove_labels(github_repo, pr_number, labels: opts[:remove], **opts)

  puts
end
