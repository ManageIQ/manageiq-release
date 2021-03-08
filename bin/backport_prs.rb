#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

ManageIQ::Release::StringFormatting.enable

opts = Optimist.options do
  opt :branch,  "The target branch to backport to.", :type => :string, :required => true

  opt :skip,    "The repo(s) to skip.",              :type => :strings

  ManageIQ::Release.common_options(self, :except => :dry_run, :repo_set_default => nil)
end
branch = opts[:branch]
opts[:repo_set] = branch unless opts[:repo] || opts[:repo_set]

repos = ManageIQ::Release.repos_for(opts)

query = "is:merged label:#{branch}/yes "
query << repos.map { |r| "repo:#{r.github_repo}" }.join(" ")
if opts[:skip]
  query << " " << opts[:skip].map { |r| "-repo:#{ManageIQ::Release.repo_for(r).github_repo}" }.join(" ")
end

github = ManageIQ::Release.github
all_prs =
  github
    .search_issues(query)["items"]
    .sort_by { |pr| pr.closed_at }
    .group_by { |pr| pr.repository_url.split("/").last(2).join("/") }

repos = repos.index_by(&:github_repo)

all_prs.each do |github_repo, prs|
  puts ManageIQ::Release.header(github_repo)

  repo = repos[github_repo]
  repo.checkout(branch)
  repo.fetch

  prs.each do |pr|
    merge_commit_sha = github.pull_request(github_repo, pr.number).merge_commit_sha

    puts
    puts "** #{github_repo}##{pr.number} (#{merge_commit_sha[0, 8]})".cyan
    puts

    begin
      repo.git.cherry_pick("-m1", "-x", merge_commit_sha)
      cherry_picked = true
    rescue MiniGit::GitError
      repo.git.cherry_pick("--abort")
      cherry_picked = false
    end

    if cherry_picked
      puts
      repo.git.log("-1")
      puts

      repo.git.push("origin", branch)

      backport_commit = repo.git.capturing.rev_parse("HEAD").chomp
      backport_log    = repo.git.capturing.log("-1").chomp
      github.add_comment(github_repo, pr.number, <<~BODY)
        Backported to `#{branch}` in commit #{backport_commit}.

        ```text
        #{backport_log}
        ```
      BODY

      github.remove_label(github_repo, pr.number, "#{branch}/yes")
      github.add_labels_to_an_issue(github_repo, pr.number, ["#{branch}/backported"])
    else
      github.add_comment(github_repo, pr.number, <<~BODY)
        @#{pr.user.login} A conflict occurred during the backport of this pull request to `#{branch}`.

        If this pull request is based on another pull request that has not been \
        marked for backport, add the appropriate labels to the other pull request. \
        Otherwise, please create a new pull request direct to the `#{branch}` branch \
        in order to resolve this.
      BODY

      github.remove_label(github_repo, pr.number, "#{branch}/yes")
      github.add_labels_to_an_issue(github_repo, pr.number, ["#{branch}/conflict"])

      puts
      puts "A conflict occurred during backport of #{merge_commit_sha}".red
      puts "Stopping backports for #{github_repo}".red
      break
    end
  end

  puts
end
