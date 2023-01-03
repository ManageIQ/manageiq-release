#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :org,    "The target GitHub org",          :type => :string, :required => true
  opt :prefix, "The repo prefix in the new org", :default => "manageiq"

  ManageIQ::Release.common_options(self)
end

def create_repo(org, name, dry_run:, **_)
  puts "Creating #{org}/#{name}"
  if dry_run
    puts "** dry_run: github.create_repository(#{name.inspect}, :organization => #{org.inspect}, :private => false)"
  else
    github.create_repository(name, :organization => org, :private => false)
  end
end

def github
  ManageIQ::Release.github
end

ManageIQ::Release.repos_for(**opts).each do |repo|
  upstream_name = repo.github_repo.split("/").last
  next if repo.options.has_real_releases && !upstream_name.start_with?("container-")

  puts ManageIQ::Release.header(repo.github_repo)

  mirror_name =
    if upstream_name.start_with?("manageiq")
      upstream_name.sub(/^manageiq/, opts[:prefix])
    else
      "#{opts[:prefix]}-#{upstream_name}"
    end

  create_repo(opts[:org], mirror_name, **opts)
  puts
end
