#!/usr/bin/env ruby

require "bundler/inline"
gemfile do
  source "https://rubygems.org"
  gem "multi_repo", require: "multi_repo/cli", path: File.expand_path("~/dev/multi_repo")
end

opts = Optimist.options do
  opt :org,    "The target GitHub org",          :type => :string, :required => true
  opt :prefix, "The repo prefix in the new org", :default => "manageiq"

  MultiRepo::CLI.common_options(self)
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
  MultiRepo::Service.Github.client
end

MultiRepo::CLI.repos_for(**opts).each do |repo|
  upstream_name = repo.short_name
  next if repo.options.has_real_releases && !upstream_name.start_with?("container-")

  puts MultiRepo::CLI.header(repo.name)

  mirror_name =
    if upstream_name.start_with?("manageiq")
      upstream_name.sub(/^manageiq/, opts[:prefix])
    else
      "#{opts[:prefix]}-#{upstream_name}"
    end

  create_repo(opts[:org], mirror_name, **opts)
  puts
end
