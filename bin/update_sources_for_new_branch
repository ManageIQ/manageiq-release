#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :branch, "The new branch name.", :type => :string, :required => true

  ManageIQ::Release.common_options(self, :repo_set_default => nil)
end
opts[:repo_set] = opts[:branch] unless opts[:repo] || opts[:branch]

review = StringIO.new
post_review = StringIO.new

ManageIQ::Release.each_repo(opts) do |repo|
  repo.chdir do
    repo.fetch
    repo.checkout(opts[:branch])

    # Update the README badges
    readme = File.read("README.md")
    readme.gsub!("coveralls.io/repos/#{repo.github_repo}/badge.svg?branch=master", "coveralls.io/repos/#{repo.github_repo}/badge.svg?branch=#{opts[:branch]}")
    readme.gsub!("coveralls.io/github/#{repo.github_repo}?branch=master", "coveralls.io/github/#{repo.github_repo}?branch=#{opts[:branch]}")
    readme.gsub!("hakiri.io/github/#{repo.github_repo}/master", "hakiri.io/github/#{repo.github_repo}/#{opts[:branch]}")
    readme.gsub!("buildstats.info/travisci/chart/#{repo.github_repo}?branch=master", "buildstats.info/travisci/chart/#{repo.github_repo}?branch=#{opts[:branch]}")
    File.write("README.md", readme)

    # Update the Gemfile for manageiq
    if repo.name == "manageiq"
      gemfile = File.read("Gemfile")
      gemfile.gsub!(/^(\s*gem "manageiq-.+:branch => )"master"$/, %Q(\\1"#{opts[:branch]}"))
      File.write("Gemfile", gemfile)
    end

    # Update the bin/setup files
    if File.exist?("bin/setup")
      setup = File.read("bin/setup")
      setup.gsub!(%r{system "git clone https://github.com/ManageIQ/manageiq.git.+$}, %Q(system "git clone https://github.com/ManageIQ/manageiq.git --branch #{opts[:branch]} --depth 1 spec/manageiq"))
      File.write("bin/setup", setup)
    end

    review.puts ManageIQ::Release.header(repo.name)
    review.puts `git --no-pager diff`
    review.puts

    post_review.puts "pushd #{repo.path}; git commit -am 'Update references for #{opts[:branch]} branch'; OVERRIDE=true git push origin #{opts[:branch]}; popd"
  end
end

puts
puts ManageIQ::Release.separator
puts
puts "Review the following:"
puts
puts review.string
puts
puts "If the changes are all correct,"
puts "  run the following script to push all of the new changes"
puts
puts post_review.string
puts
