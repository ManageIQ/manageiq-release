#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :branch,  "The target branch to backport to.", :type => :string, :required => true

  opt :skip,    "The repo(s) to skip.",              :type => :strings

  banner ""
  banner "Commands:"
  opt :list, "List PRs for the specified labels and exit.", :type => :strings

  ManageIQ::Release.common_options(self, :repo_set_default => nil)
end
branch = opts[:branch]
opts[:repo_set] = branch unless opts[:repo] || opts[:repo_set]

repos = ManageIQ::Release.repos_for(**opts)
if opts[:skip]&.any?
  to_skip = opts[:skip].map { |r| ManageIQ::Release.repo_for(r).github_repo }.to_set
  repos.reject! { |r| to_skip.include?(r.github_repo) }
end
repos = repos.index_by(&:github_repo)

def list_prs(branch, repos, opts)
  labels  = opts[:list].map { |l| l.start_with?(branch) ? l : "#{branch}/#{l}" }
  all_prs = ManageIQ::Release::BackportPrs.search(repos.keys, labels)

  table = all_prs.flat_map do |_github_repo, prs|
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

  backports = ManageIQ::Release::BackportPrs.search(repos.keys, "#{branch}/yes").sort!
  backports.each do |github_repo, prs|
    puts ManageIQ::Release.header(github_repo)

    backport_prs = ManageIQ::Release::BackportPrs.new(repos[github_repo], opts.merge(:prs => prs))
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
