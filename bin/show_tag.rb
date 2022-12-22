#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'more_core_extensions/core_ext/array/tableize'
require 'optimist'

opts = Optimist.options do
  opt :tag, "The tag name.", :type => :string, :required => true

  ManageIQ::Release.common_options(self, :except => :dry_run, :repo_set_default => nil)
end
opts[:repo_set] = opts[:tag].split("-").first unless opts[:repo] || opts[:repo_set]

HEADER = %w(Repo SHA Message).freeze

def show_tag(repo, tag)
  line =
    begin
      repo.git.capturing.show({:summary => true, :oneline => true}, tag)
    rescue MiniGit::GitError => err
      ""
    end

  sha, message = line.split(" ", 2)
  [repo.name, sha, message]
end

repos = ManageIQ::Release.repos_for(**opts).reject { |repo| repo.options.has_real_releases }
table = [HEADER] + repos.collect { |repo| show_tag(repo, opts[:tag]) }
puts table.tableize(:max_width => 75)
