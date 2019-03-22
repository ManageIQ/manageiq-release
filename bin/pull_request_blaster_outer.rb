#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'
require 'pp'
require 'yaml'

class PullRequestBlasterOuter

  def initialize(options)
    @conf = configuration(options)

    @conf[:base]    = options[:base]    || @conf[:base]
    @conf[:head]    = options[:head]    || @conf[:head]
    @conf[:dir]     = options[:dir]     || @conf[:dir]
    @conf[:script]  = options[:script]  || @conf[:script]
    @conf[:message] = options[:message] || @conf[:message]
    @conf[:repo]    = options[:repo]    || @conf[:repo]
    @conf[:dry_run] = options[:dry_run] || @conf[:dry_run]
    @conf[:config]  = options[:config]
  end

  def blast
    results = {}
    ManageIQ::Release.each_repo(@conf[:repo]) do |repo|
      results[repo.github_repo] = ManageIQ::Release::PullRequestBlasterOuter.new(repo, @conf[:config], @conf.slice(:base, :head, :script, :dry_run, :message)).blast
    end

    pp results
  end

  def configuration(options)
    config_file = YAML.load_file(options[:config])
    config = {}
    return unless config_file
    symbolise(config_file)
  end

  # code from https://gist.github.com/Integralist/9503099
  def symbolise(obj)
    if obj.is_a? Hash
      return obj.inject({}) do |hash, (k, v)|
        hash.tap { |h| h[k.to_sym] = symbolise(v) }
      end
    elsif obj.is_a? Array
      return obj.map { |hash| symbolise(hash) }
    end
    obj
  end
end

options = Optimist.options do
  opt :config,  "Path to Blaster configuration file", :type => :string,  :required => false
  opt :base,    "The name of the branch you want the changes pulled into.",   :type => :string, :required => false
  opt :head,    "The name of the branch containing the changes.",             :type => :string, :required => false
  opt :script,  "The path to the script that will update the desired files.", :type => :string, :required => false
  opt :message, "The commit message and PR title for this change.",           :type => :string, :required => false

  opt :repo,    "The repo to update. If not passed, will try all repos in config/repos.yml.", :type => :strings
  opt :dry_run, "Make local changes, but don't fork, push, or create the pull request.", :default => false
end

blaster = PullRequestBlasterOuter.new(options)
blaster.blast
