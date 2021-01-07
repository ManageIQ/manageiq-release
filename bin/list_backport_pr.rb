#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'more_core_extensions/core_ext/array/tableize'
require 'optimist'

opts = Optimist.options do
  opt :branch,  "The target branch to backport to.", :type => :string,  :required => true

  opt :blocker,  "List 'blocker' PRs only.",       :type => :boolean, :default => false
  opt :open,     "Open all links in a browser.",   :type => :boolean, :default => false
  opt :proposed, "List yes? PRs instead",          :type => :boolean, :default => false
  opt :skip,     "The repo(s) to skip.",           :type => :strings

  ManageIQ::Release.common_options(self, :except => :dry_run, :repo_set_default => nil)
end

branch = opts[:branch]
EXTRA_LABELS = ["blocker", "bugzilla needed", "#{branch}/conflict"]

query = ""
if opts[:repo] || opts[:repo_set]
  repos = ManageIQ::Release.repos_for(opts)
  Optimist.die "--repo or --repo-set not found" if repos.nil?

  query << " " << repos.map { |r| "repo:#{r.github_repo}" }.join(" ")
end
if opts[:skip]
  repos = opts[:skip].map { |r| ManageIQ::Release.repo_for(r) }

  query << " " << repos.map { |r| "-repo:#{r.github_repo}" }.join(" ")
end
query = "org:ManageIQ" if query.empty?

yes_label = opts[:proposed] ? "yes?" : "yes"
query << " is:merged label:#{branch}/#{yes_label}"
query << " label:blocker" if opts[:blocker]

puts "Querying: #{query}"
puts
prs = ManageIQ::Release.github.search_issues(query)["items"]

pr_list = []
prs.each do |pr|
  repo = pr.repository_url.split("/").last
  label = EXTRA_LABELS & pr.labels.collect(&:name)
  pr_list << {
               "Repo"  => repo,
               "PR"    => pr.number,
               "Label" => label.empty? ? "" : label.join(","),
               "Date"  => pr.closed_at,
               "Link"  => pr.html_url
             }
end

unless pr_list.empty?
  sorted_list = pr_list.sort_by { |v| [ v["Repo"], v["Date"] ] }
  table = sorted_list.tableize(:columns => ["Repo", "PR", "Label"])
  puts table
  sorted_list.each { |pr| `open #{pr["Link"]}` } if opts[:open]
end
