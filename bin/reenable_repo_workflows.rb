#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  ManageIQ::Release.common_options(self, :only => :dry_run)
end

def enable_repo(github, repo_name, workflow_url, workflow_id, dry_run: false, **_)
  puts "** Enabling #{workflow_url} (#{workflow_id})"

  if dry_run
    puts "** dry_run: github.put(\"repos/#{repo_name}/actions/workflows/#{workflow_id}/enable\")"
  else
    github.put("repos/#{repo_name}/actions/workflows/#{workflow_id}/enable")
  end
end

github = ManageIQ::Release.github

ManageIQ::Release.github_repo_names_for("ManageIQ").each do |repo_name|
  puts ManageIQ::Release.header(repo_name)

  disabled_workflows = github.workflows(repo_name)[:workflows].select { |w| w.state == "disabled_inactivity" }
  if disabled_workflows.any?
    disabled_workflows.each do |w|
      enable_repo(github, repo_name, w.html_url, w.id, **opts)
    end
  else
    puts "** No disabled workflows found"
  end

  puts
end
