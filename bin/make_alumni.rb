#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :users, "The users to make alumni.",     :type => :strings, :required => true
  opt :org,   "The org in which user belongs", :default => "ManageIQ"

  ManageIQ::Release.common_options(self, :only => :dry_run)
end

class ManageIQ::Release::MakeAlumni
  attr_reader :org, :dry_run

  def initialize(org:, dry_run:, **_)
    @org     = org
    @dry_run = dry_run
  end

  def run(user)
    progress = ManageIQ::Release.progress_bar(teams.size + repos.size)

    add_team_membership("alumni", user)
    progress.increment

    non_alumni_teams = teams - ["alumni"]
    non_alumni_teams.each do |team|
      remove_team_membership(team, user)
      progress.increment
    end

    repos.each do |repo|
      remove_collaborator(repo, user)
      progress.increment
    end

    progress.finish
  end

  private

  def team_ids
    @team_ids ||= github.org_teams(org).map { |t| [t.slug, t.id] }.sort.to_h
  end

  def teams
    @teams ||= team_ids.keys
  end

  def repos
    @repos ||= github.org_repos(org).reject(&:archived?).map(&:full_name).sort
  end

  def add_team_membership(team, user)
    team_id = team_ids[team]

    if dry_run
      puts "** dry-run: github.add_team_membership(#{team_id.inspect}, #{user.inspect})"
    else
      github.add_team_membership(team_id, user)
    end
  end

  def remove_team_membership(team, user)
    team_id = team_ids[team]

    if dry_run
      puts "** dry-run: github.remove_team_membership(#{team_id.inspect}, #{user.inspect})"
    else
      github.remove_team_membership(team_id, user)
    end
  end

  def remove_collaborator(repo, user)
    if dry_run
      puts "** dry-run: github.remove_collaborator(#{repo.inspect}, #{user.inspect})"
    else
      github.remove_collaborator(repo, user)
    end
  end

  def github
    ManageIQ::Release.github
  end
end

make_alumni = ManageIQ::Release::MakeAlumni.new(opts)
opts[:users].each do |user|
  puts ManageIQ::Release.header(user)
  make_alumni.run(user)
end
