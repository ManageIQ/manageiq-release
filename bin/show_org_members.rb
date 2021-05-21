#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :org,    "The org to list the users for",    :default => "ManageIQ"
  opt :team,   "Show members of a specific team",  :type => :string
  opt :alumni, "Whether or not to include alumni", :default => false
end

def github
  ManageIQ::Release.github
end

def org_members(org:, **_)
  github.org_members(org).map(&:login).sort_by(&:downcase)
end

def team_members(org:, team:, **_)
  team_id = github.org_teams(org).detect { |t| t.slug == team }.id
  github.team_members(team_id).map(&:login).sort_by(&:downcase)
end

members  = opts[:team] ? team_members(opts) : org_members(opts)
members -= team_members(opts.merge(team: "alumni")) unless opts[:alumni]

puts members
