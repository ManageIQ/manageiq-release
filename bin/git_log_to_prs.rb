#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :file, "File containing output from running show_commit_history", :type => :string,  :required => true
  opt :md,   "Output in markdown format", :default => true

  ManageIQ::Release.common_options(self, :except => :dry_run)
end

file = opts[:file]
repo = nil
File.foreach(file) do |line|
  if line.match(/=== (\S+) ===/)
    repo = $1
    puts opts[:md] ? line + "<br/>" : line
  end

  if line.match(/Merge pull request #(\d+)\b/)
    pr_num = $1
    pr_url = "https://github.com/ManageIQ/#{repo}/pull/#{pr_num}"

    # puts "Requesting: #{pr_url}"
    pr = `curl -s #{pr_url}`

    pr_title = pr.match(/<title>(.*)<\/title>/)[1]
    if opts[:md]
      puts "[#{pr_title}](#{pr_url})<br/>"
    else
      puts pr_title
    end

    sleep 1 # To avoid "You have triggered an abuse detection mechanism." from github
  end
end
