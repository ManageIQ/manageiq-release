#!/usr/bin/env ruby

require "bundler/inline"
gemfile do
  source "https://rubygems.org"
  gem "multi_repo", require: "multi_repo/cli", path: File.expand_path("~/dev/multi_repo")
  gem "activesupport"
  gem "more_core_extensions"
end
require "active_support/core_ext/enumerable"
require "active_support/core_ext/object/blank"
require "more_core_extensions/core_ext/hash/sorting"

opts = Optimist.options do
  opt :branch,  "The target branch to backport to.", :type => :string, :required => true

  opt :skip,    "The repo(s) to skip.",              :type => :strings

  banner ""
  banner "Commands:"
  opt :list, "List PRs for the specified labels and exit.", :type => :strings

  MultiRepo::CLI.common_options(self, :repo_set_default => nil)
end
branch = opts[:branch]
opts[:repo_set] = branch unless opts[:repo] || opts[:repo_set]

class BackportPrs
  def self.search(repo_names, backport_labels)
    query = "is:merged "
    query << repo_names.map { |r| "repo:#{r}" }.join(" ")
    Array(backport_labels).each do |l|
      query << " label:#{l}"
    end

    MultiRepo::Service::Github
      .client
      .search_issues(query)["items"]
      .sort_by(&:closed_at)
      .group_by { |pr| pr.repository_url.split("/").last(2).join("/") }
  end

  attr_reader :repo, :repo_name, :branch, :prs, :stats, :dry_run, :github

  def initialize(repo, branch:, prs:, dry_run: false, **_)
    @repo      = repo
    @repo_name = repo.name
    @branch    = branch
    @prs       = prs
    @dry_run   = dry_run
    @github ||= MultiRepo::Service::Github.new(:dry_run => dry_run)

    @stats = {
      :skipped  => [],
      :success  => [],
      :conflict => []
    }
  end

  def run
    repo.git.fetch
    repo.git.hard_checkout(branch)
    backport_prs
  end

  private

  def backport_prs
    prs.each do |pr|
      puts
      puts "** #{pr.html_url}".cyan.bold

      if already_on_branch?(pr)
        @stats[:skipped] << pr.html_url

        handle_already_on_branch(pr)

        puts "The commit already exists on the branch. Skipping.".yellow
      elsif backport_pr(pr)
        @stats[:success] << pr.html_url

        puts
        repo.git.client.log("-1")
        puts
      else
        @stats[:conflict] << pr.html_url

        puts
        puts "A conflict was encountered during backport.".red
        puts "Stopping backports for #{repo_name}.".red
        break
      end
    end
    puts
  end

  def backport_pr(pr)
    success, failure_diff = cherry_pick(merge_commit_sha(pr.number))

    if success
      message = <<~BODY
        Backported to `#{branch}` in commit #{backport_commit_sha}.

        ```text
        #{backport_commit_log}
        ```
      BODY

      push_backport_commit
      add_comment(pr.number, message)
      remove_label(pr.number, "#{branch}/yes")
      remove_label(pr.number, "#{branch}/conflict")
      add_label(pr.number, "#{branch}/backported")

      true
    else
      unless labeled_conflict?(pr)
        message = <<~BODY
          @#{pr.user.login} A conflict occurred during the backport of this pull request to `#{branch}`.

          If this pull request is based on another pull request that has not been \
          marked for backport, add the appropriate labels to the other pull request. \
          Otherwise, please create a new pull request direct to the `#{branch}` branch \
          in order to resolve this.

          Conflict details:

          ```diff
          #{failure_diff}
          ```
        BODY
        message = "#{message[0, 65_530]}\n```\n" if message.size > 65_535

        add_comment(pr.number, message)
        add_label(pr.number, "#{branch}/conflict")
      end

      false
    end
  end

  def handle_already_on_branch(pr)
    message = <<~BODY
      Skipping backport to `#{branch}`, because it is already in the branch.
    BODY

    add_comment(pr.number, message)
    remove_label(pr.number, "#{branch}/yes")
    remove_label(pr.number, "#{branch}/conflict")

    true
  end

  def already_on_branch?(pr)
    repo.git.client.capturing.branch("--contains", merge_commit_sha(pr.number), branch).present?
  end

  def labeled_conflict?(pr)
    pr.labels.any? { |l| l.name == "#{branch}/conflict" }
  end

  def merge_commit_sha(pr_number)
    @merge_commit_shas ||= {}
    @merge_commit_shas[pr_number] ||= github.client.pull_request(repo_name, pr_number).merge_commit_sha
  end

  def backport_commit_sha
    repo.git.client.capturing.rev_parse("HEAD").chomp
  end

  def backport_commit_log
    repo.git.client.capturing.log("-1").chomp
  end

  def cherry_pick(sha)
    repo.git.client.cherry_pick("-m1", "-x", sha)
    return true, nil
  rescue MiniGit::GitError
    diff = repo.git.client.capturing.diff.chomp
    repo.git.client.cherry_pick("--abort")
    return false, diff
  end

  def push_backport_commit
    remote = "origin"
    if dry_run
      puts "** dry_run: git.push(#{remote.inspect}, #{branch.inspect})".light_black
    else
      repo.git.client.push(remote, branch)
    end
  end

  def add_comment(pr_number, body)
    if dry_run
      puts "** dry_run: github.add_comment(#{repo_name.inspect}, #{pr_number.inspect}, #{body.pretty_inspect})".light_black
    else
      github.client.add_comment(repo_name, pr_number, body)
    end
  end

  def remove_label(pr_number, label)
    if dry_run
      puts "** dry_run: github.remove_label(#{repo_name.inspect}, #{pr_number.inspect}, #{label.inspect})".light_black
    else
      github.client.remove_label(repo_name, pr_number, label)
    end
  rescue Octokit::NotFound
    # Ignore labels that are not found, because we want them removed anyway
  end

  def add_label(pr_number, label)
    label = [label]
    if dry_run
      puts "** dry_run: github.add_labels_to_an_issue(#{repo_name.inspect}, #{pr_number.inspect}, #{label.inspect})".light_black
    else
      github.client.add_labels_to_an_issue(repo_name, pr_number, label)
    end
  end
end

repos = MultiRepo::CLI.repos_for(**opts)
if opts[:skip]&.any?
  to_skip = opts[:skip].map { |r| MultiRepo::CLI.repo_for(r).name }.to_set
  repos.reject! { |r| to_skip.include?(r.name) }
end
repos = repos.index_by(&:name)

def list_prs(branch, repos, opts)
  labels  = opts[:list].map { |l| l.start_with?(branch) ? l : "#{branch}/#{l}" }
  all_prs = BackportPrs.search(repos.keys, labels)

  table = all_prs.flat_map do |_name, prs|
    prs.map do |pr|
      {
        "PR"     => pr.html_url,
        "Date"   => pr.closed_at.iso8601,
        "Labels" => pr.labels.map(&:name).select { |l| l.start_with?(branch) }.join(",")
      }
    end
  end

  if table.any?
    require 'more_core_extensions/core_ext/array/tableize'
    puts table.tableize(:columns => ["PR", "Date", "Labels"])
  end
end

def backport_prs(branch, repos, opts)
  stats = {
    :success  => [],
    :skipped  => [],
    :conflict => []
  }

  backports = BackportPrs.search(repos.keys, "#{branch}/yes").sort!
  backports.each do |name, prs|
    puts MultiRepo::CLI.header(name)

    backport_prs = BackportPrs.new(repos[name], **opts.merge(:prs => prs))
    backport_prs.run
    stats.each_key { |k| stats[k].concat(backport_prs.stats[k]) }
  end

  puts
  puts "Summary:"
  puts
  if stats[:success].any?
    puts "The following PRs were successfully backported:"
    puts stats[:success].map { |n| ("* #{n}") }
    puts
  end
  if stats[:skipped].any?
    puts "The following PRs were skipped:"
    puts stats[:skipped].map { |n| ("* #{n}") }
    puts
  end
  if stats[:conflict].any?
    puts "The following PRs had conflicts:"
    puts stats[:conflict].map { |n| ("* #{n}") }
    puts
  end
  puts
end

if opts[:list]
  list_prs(branch, repos, opts)
else
  backport_prs(branch, repos, opts)
end
