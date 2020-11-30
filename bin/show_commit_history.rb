#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

DISPLAY_FORMATS = %w[commit pr-title pr-label]

opts = Optimist.options do
  opt :from,    "The commit log 'from' ref", :type => :string,  :required => true
  opt :to,      "The commit log 'to' ref" ,  :type => :string,  :required => true
  opt :display, "How to display the history. Valid values are: #{DISPLAY_FORMATS.join(", ")}", :default => "commit"

  opt :skip,   "The repos to skip", :default => ["manageiq-documentation"]

  ManageIQ::Release.common_options(self, :except => :dry_run)
end
Optimist.die :display, "must be one of: #{DISPLAY_FORMATS.join(", ")}" unless DISPLAY_FORMATS.include?(opts[:display])

range = "#{opts[:from]}..#{opts[:to]}"
github = ManageIQ::Release.github

puts "Git commit log between #{opts[:from]} and #{opts[:to]}\n\n"

ManageIQ::Release.repos_for(opts).each do |repo|
  next if repo.options.has_real_releases
  next if opts[:skip].include?(repo.name)

  puts ManageIQ::Release.header(repo.name)
  repo.fetch(output: false)

  case opts[:display]
  when "pr-label", "pr-title"
    pr_label_display = opts[:display] == "pr-label"

    results = {}
    if pr_label_display
      results["bug"] = []
      results["enhancement"] = []
    end
    results["other"] = []

    log = repo.git.capturing.log({:oneline => true}, range)
    log.lines.each do |line|
      next unless (match = line.match(/Merge pull request #(\d+)\b/))

      pr = github.pull_request(repo.github_repo, match[1])
      label = pr.labels.detect { |l| results.key?(l.name) }&.name || "other"
      results[label] << pr
    end

    results.each do |label, prs|
      next if prs.blank?

      puts "\n## #{label.titleize}\n\n" if pr_label_display
      prs.each do |pr|
        puts "* #{pr.title} [[##{pr.number}]](#{pr.html_url})"
      end
    end
  when "commit"
    repo.git.git([{:no_pager => true}, :log, {:oneline => true, :decorate => true, :graph => true}], range)
  end

  puts
end
