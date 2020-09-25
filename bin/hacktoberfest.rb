#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :apply, "Apply the `hacktoberfest` label to `good first issue` labels. "\
              "Pass --no-apply to remove the `hacktoberfest` label",
              :type => :boolean, :default => true

  ManageIQ::Release.common_options(self, :only => :dry_run)
end

class ManageIQ::Release::Hacktoberfest
  attr_reader :apply, :dry_run

  def initialize(apply:, dry_run: false, **_)
    @apply   = apply
    @dry_run = dry_run
  end

  def run
    if apply
      good_first_issues.each { |issue| add_hacktoberfest_label(issue) }
    else
      hacktoberfest_issues.each { |issue| remove_hacktoberfest_label(issue) }
    end
  end

  private

  def good_first_issues
    sorted_issues("org:ManageIQ archived:false is:open label:\"good first issue\" -label:hacktoberfest")
  end

  def hacktoberfest_issues
    sorted_issues("org:ManageIQ archived:false is:open label:hacktoberfest")
  end

  def sorted_issues(query)
    github.search_issues(query).items.sort_by { |issue| issue_id(issue) }
  end

  def add_hacktoberfest_label(issue)
    labels = ["hacktoberfest"]
    repo, number = issue_id(issue)
    puts "Adding #{labels.first.inspect} label to issue #{repo}##{number}"

    if dry_run
      puts "** dry_run: github.add_labels_to_an_issue(#{repo.inspect}, #{number.inspect}, #{labels.inspect})"
    else
      github.add_labels_to_an_issue(repo, number, labels)
    end
  end

  def remove_hacktoberfest_label(issue)
    label = "hacktoberfest"
    repo, number = issue_id(issue)
    puts "Removing #{label.inspect} label from issue #{repo}##{number}"

    if dry_run
      puts "** dry_run: github.remove_label(#{repo.inspect}, #{number.inspect}, #{label.inspect})"
    else
      github.remove_label(repo, number, label)
    end
  end

  def issue_id(issue)
    [issue_repo(issue), issue.number]
  end

  def issue_repo(issue)
    issue.repository_url.split("/").last(2).join("/")
  end

  def github
    ManageIQ::Release.github
  end
end

ManageIQ::Release::Hacktoberfest.new(opts).run
