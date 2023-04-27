#!/usr/bin/env ruby

require "bundler/inline"
gemfile do
  source "https://rubygems.org"
  gem "multi_repo", require: "multi_repo/cli", path: File.expand_path("~/dev/multi_repo")
end

opts = Optimist.options do
  opt :branch,        "The new branch name.",                                   :type => :string, :required => true
  opt :next_branch,   "The next branch name.",                                  :type => :string, :required => true
  opt :source_branch, "The source branch from which to create the new branch.", :default => "master"

  MultiRepo::CLI.common_options(self, :repo_set_default => nil)
end
opts[:repo_set] = opts[:branch] unless opts[:repo] || opts[:repo_set]

repos = MultiRepo::CLI.repos_for(**opts)
Optimist.die(:branch, "not found in config/repos*.yml") if repos.nil?

Optimist.die(:branch, "not found in config/labels.yml") unless MultiRepo::CLI::Labels.config.key?("release_#{opts[:branch]}")

class ReleaseBranch
  attr_reader :repo, :branch, :next_branch, :source_branch, :dry_run

  def self.first_time_setup(source_branch)
    return if @first_time_setup

    # Ensure we move core to the source branch so that the symlinks from the
    # other repos are correct
    core_repo = MultiRepo::Repo.new("ManageIQ/manageiq")
    core_repo.fetch
    core_repo.checkout(source_branch, "origin/#{source_branch}")

    @first_time_setup = true
  end

  def initialize(repo, branch:, next_branch:, source_branch: "master", dry_run:, **_)
    @repo          = repo
    @branch        = branch
    @next_branch   = next_branch
    @source_branch = source_branch
    @dry_run       = dry_run

    @branch_changes = false
    @master_changes = false
  end

  def run
    self.class.first_time_setup(source_branch)

    repo.git.fetch
    repo.git.hard_checkout(branch, "origin/#{source_branch}")

    repo.chdir do
      symlink_spec_manageiq

      @branch_changes = apply_common_branch_changes
      @branch_changes = apply_branch_changes || @branch_changes

      @master_changes = apply_master_changes
    end

    # For core, ensure we move core back to the source branch so that the
    # symlinks from the other repos are correct. However, just do a regular
    # checkout and not a hard/clean checkout, as we need to keep the commits
    # to push later.
    repo.git.client.checkout(source_branch) if repo.name == "ManageIQ/manageiq"
  end

  def pretty_log(target_branch, count)
    repo.git.client.capturing.log("-#{count}", "--color", "-p", target_branch, :graph => true, :pretty => "format:\%C(auto)\%h -\%d \%s \%C(green)(\%cr) \%C(cyan)<\%an>\%C(reset)").chomp
  end

  def review
    branch_diff = pretty_log(branch, 2) if @branch_changes
    master_diff = pretty_log("master", 1) if @master_changes

    [
      MultiRepo::CLI.header("#{branch} changes", "-"),
      branch_diff,
      MultiRepo::CLI.header("master changes", "-"),
      master_diff
    ].compact.join("\n\n")
  end

  def post_review
    # TODO: Automate this with some questions at branch time
    branches = []
    branches << branch
    branches << "master" if @master_changes
    return if branches.empty?

    "pushd #{repo.path}; OVERRIDE=true git push origin #{branches.join(" ")}; popd"
  end

  private

  def symlink_spec_manageiq
    return if repo.name == "ManageIQ/manageiq"
    return unless Pathname.new("spec").directory?

    FileUtils.rm_f("spec/manageiq")
    FileUtils.ln_s("../../manageiq", "spec/manageiq")
  end

  def apply_common_branch_changes
    before_install = editing_file("bin/before_install") do |contents|
      contents.sub(/(git clone.+? --branch )#{source_branch}/, "\\1#{branch}")
    end

    readme = editing_file("README.md") do |contents|
      contents.gsub!(/(github\.com.+?branch=)#{source_branch}\b/, "\\1#{branch}")
      contents.gsub!(/(github\.com.+?\.svg)\)/, "\\1?branch=#{branch})")
      contents.gsub!(/(coveralls\.io.+?branch=)#{source_branch}\b/, "\\1#{branch}")
      contents.gsub!(/Build history for (?:master|#{source_branch}) branch/, "Build history for #{branch} branch")
      contents.gsub!(/(buildstats\.info.+?branch=)#{source_branch}\b/, "\\1#{branch}")
      contents
    end

    files_to_update = [before_install, readme].compact
    if files_to_update.any?
      repo.git.client.add(*files_to_update)
      repo.git.client.commit("-m", "Changes for new branch #{branch}.")
      true
    else
      false
    end
  end

  def apply_branch_changes
    return unless repo.options.has_rake_release_new_branch

    rake_release("new_branch")

    true
  end

  def apply_master_changes
    return unless repo.options.has_rake_release_new_branch_master

    repo.git.hard_checkout("master", "origin/master")
    rake_release("new_branch_master")

    # Go back to the previous branch
    repo.git.client.checkout(branch)

    true
  end

  def editing_file(file)
    return nil unless File.exist?(file)

    contents = File.read(file)
    new_contents = yield contents.dup

    if new_contents != contents
      File.write(file, new_contents)
      file
    else
      nil
    end
  end

  def rake_release(task)
    rake("release:#{task}", {"RELEASE_BRANCH" => branch, "RELEASE_BRANCH_NEXT" => next_branch})
  end

  def rake(task, env)
    if dry_run
      env_str = env.map { |k, v| "#{k}=#{v}" }.join(" ")

      puts "** dry-run: bundle check || bundle update".light_black
      puts "** dry-run: #{env_str} bundle exec rake #{task}".light_black
    else
      Bundler.with_unbundled_env do
        system!("bundle check || bundle update", :chdir => repo.path)
        system!(env, "bundle exec rake #{task}", :chdir => repo.path)
      end
    end
  end

  def system!(*args)
    exit($?.exitstatus) unless system(*args)
  end
end

review = StringIO.new
post_review = StringIO.new

repos.each do |repo|
  next if repo.config.has_real_releases

  release_branch = ReleaseBranch.new(repo, **opts)

  puts MultiRepo::CLI.header("Branching #{repo.name}")
  release_branch.run
  puts

  review.puts MultiRepo::CLI.header(repo.name)
  review.puts release_branch.review
  review.puts

  post_msg = release_branch.post_review
  post_review.puts post_msg if post_msg
end

puts
puts MultiRepo::CLI.separator
puts
puts "Review the following:"
puts
puts review.string
puts
puts "If all changes are correct,"
puts "  run the following script to push all of the new branches"
puts
puts post_review.string
puts
puts "Once completed, be sure to follow the rest of the release checklist."
