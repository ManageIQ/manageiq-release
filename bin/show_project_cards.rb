#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :project_id, "The project ID",                :type => :integer, :required => true
  opt :column,     "The column within the project", :type => :string,  :required => true

  ManageIQ::Release.common_options(self, :only => :repo)
end

github = ManageIQ::Release.github
repo = opts[:repo].first
projects_headers = {:accept => "application/vnd.github.inertia-preview+json"}

projects = github.send(repo.include?("/") ? :projects : :org_projects, repo, projects_headers)
project  = projects.detect { |p| p.number == opts[:project_id] }
Optimist.die :project_id, "not found" if project.nil?

column = github.project_columns(project.id, projects_headers).detect { |c| c.name == opts[:column] }
Optimist.die :column, "not found" if column.nil?

cards = github.column_cards(column.id, projects_headers)
issues = cards.map do |card|
  org, repo, _issues, id = URI.parse(card.content_url).path.split("/").last(4)
  github.issue("#{org}/#{repo}", id)
end

issues.each do |issue|
  puts "* #{issue.title} [[##{issue.number}]](#{issue.html_url})"
end
