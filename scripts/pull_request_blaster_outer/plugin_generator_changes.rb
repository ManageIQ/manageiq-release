#! /usr/bin/env ruby

# bin/pull_request_blaster_outer.rb --base master --head plugin_generator_changes --script scripts/pull_request_blaster_outer/plugin_generator_changes.rb --message "Plugin Generator Updates" --repo_set plugins

$: << File.expand_path("../../lib", __dir__)
require "manageiq-release"
include ManageIQ::Release::PullRequestBlasterOuter::ScriptHelpers

expect_env_vars!("GITHUB_REPO")

ActiveSupport::Inflector.inflections { |i| i.acronym('ManageIQ') }

repo = ManageIQ::Release.repo_for(ENV["GITHUB_REPO"])
repo_model = repo.name.gsub("-", "/").classify

provider = repo.name.start_with?("manageiq-providers")
task = "manageiq:#{provider ? "provider" : "plugin"}"
path = repo.path.parent
extra_params = "--no-scaffolding --vcr" if provider

miq_repo = ManageIQ::Release.repo_for("ManageIQ/manageiq")
miq_repo.clean
miq_repo.fetch
miq_repo.checkout("master")
miq_repo.chdir do
  puts "** Bundling..."
  system!("bundle &>/dev/null")
  FileUtils.mkdir_p("log")  #Fix upstream
  FileUtils.cp("config/database.pg.yml", "config/database.yml") unless File.exist?("config/database.yml")
  puts "** Running generator..."
  system!("bundle exec rails generate #{task} #{repo_model} --path #{path} #{extra_params}")
end
