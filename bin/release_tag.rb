#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :tag,    "The new tag name.",       :type => :string, :required => true
  opt :branch, "The branch to tag from.", :type => :string
  opt :skip,   "The repo(s) to skip.",    :type => :strings

  ManageIQ::Release.common_options(self, :repo_set_default => nil)
end
opts[:branch] ||= opts[:tag].split("-").first
opts[:repo_set] = opts[:branch] unless opts[:repo] || opts[:repo_set]

class ReleaseTag
  attr_reader :repo, :branch, :tag, :dry_run

  def initialize(repo, branch:, tag:, dry_run: false, **_)
    @repo    = repo
    @branch  = branch
    @tag     = tag
    @dry_run = dry_run
  end

  def run
    repo.fetch
    repo.checkout(branch)
    repo.options.has_rake_release ? rake_release : tagged_release
  end

  def review
    repo.git.capturing.log("-5", :graph => true, :pretty => "format:\%h -\%d \%s (\%cr) <\%an>")
  end

  def post_review
    # TODO: Automate this with some questions at tag time
    "pushd #{repo.path}; OVERRIDE=true git push origin #{branch} #{tag}; popd"
  end

  private

  def system!(*args)
    exit($?.exitstatus) unless system(*args)
  end

  def rake_release
    if dry_run
      puts "** dry-run: bundle check || bundle update"
      puts "** dry-run: RELEASE_VERSION=#{tag} bundle exec rake release"
    else
      Bundler.with_clean_env do
        repo.chdir do
          # Ensure that spec/manageiq is symlinked
          FileUtils.ln_sf(repo.path.join("../manageiq").expand_path, repo.path.join("spec/manageiq"))

          system!("bundle check || bundle update")
          system!({"RELEASE_VERSION" => tag}, "bundle exec rake release")
        end
      end
    end
  end

  def tagged_release
    if dry_run
      puts "** dry-run: git tag #{tag} -m \"Release #{tag}\""
    else
      repo.git.tag(tag, "-m", "Release #{tag}")
    end
  end
end


review = StringIO.new
post_review = StringIO.new

# Move manageiq repo to the end of the list.  The rake release script on manageiq
#   depends on all of the other repos running their rake release scripts first.
repos = ManageIQ::Release.repos_for(**opts)
repos = repos.partition { |r| r.github_repo != "ManageIQ/manageiq" }.flatten

# However, the other plugins require that manageiq is at the right checkout in
#   order to run their rake release scripts
manageiq_repo = repos.last
puts ManageIQ::Release.header("Checking out #{manageiq_repo.name}")
manageiq_repo.fetch
manageiq_repo.checkout(opts[:branch])

repos.each do |repo|
  next if Array(opts[:skip]).include?(repo.name)
  next if repo.options.has_real_releases || repo.options.skip_tag

  release_tag = ReleaseTag.new(repo, **opts)

  puts ManageIQ::Release.header("Tagging #{repo.name}")
  release_tag.run
  puts

  review.puts ManageIQ::Release.header(repo.name)
  review.puts release_tag.review
  review.puts
  post_review.puts release_tag.post_review
end

puts
puts ManageIQ::Release.separator
puts
puts "Review the following:"
puts
puts review.string
puts
puts "If the tags are all correct,"
puts "  run the following script to push all of the new tags"
puts
puts post_review.string
puts
