#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :since, "Since what date.", :type => :string, :required => true

  ManageIQ::Release.common_options(self, :except => :dry_run)
end

class OrgStats
  def initialize(since:, **opts)
    @since = since
    @opts  = opts

    @total_commits = Hash.new(0)
    @total_merges  = Hash.new(0)
    @names = {}
  end

  def run
    ManageIQ::Release.each_repo(**@opts) { |repo| run_one(repo) }

    puts
    puts "Total Commits:"
    print_totals(@total_commits)

    puts
    puts "Grand Total Commits: #{@total_commits.values.sum}"

    puts
    puts "Total Merges:"
    print_totals(@total_merges)

    puts
    puts "Grand Total Merges: #{@total_merges.values.sum}"
  end

  private

  def run_one(repo)
    repo.fetch
    repo.checkout("master")

    puts "Commits:"
    commits = repo.git.capturing.shortlog("--summary", "--numbered", "--email", "--no-merges", "--since", @since)
    puts commits

    parse_data(commits).each do |number, name, email|
      @total_commits[email] += number.to_i
      @names[email] ||= name
    end

    puts "Merges:"
    merges = repo.git.capturing.shortlog("--summary", "--numbered", "--email", "--merges", "--since", @since, "--grep", "Merge pull request #")
    puts merges

    parse_data(merges).each do |number, name, email|
      @total_merges[email] += number.to_i
      @names[email] ||= name
    end
  end

  def parse_data(data)
    data
      .chomp
      .lines(:chomp => true)
      .map { |l| l.match(/^\s*(\d+)\s+([^<]+)<([^>]+)>/).captures }
  end

  def print_totals(totals)
    totals.sort_by { |_email, number| -number }.each do |email, number|
      puts "#{number.to_s.rjust(8)}  #{@names[email]} <#{email}>"
    end
  end
end

OrgStats.new(**opts).run
