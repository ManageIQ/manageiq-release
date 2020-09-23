#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'optimist'

opts = Optimist.options do
  opt :title,  "The new milestone title.",    :type => :string, :required => true
  opt :due_on, "The new milestone due date.", :type => :string, :required => true

  ManageIQ::Release.common_options(self)
end
Optimist.die(:due_on, "must be a date format") unless ManageIQ::Release::UpdateMilestone.valid_date?(opts[:due_on])

ManageIQ::Release.each_repo(opts) do |repo|
  ManageIQ::Release::UpdateMilestone.new(repo, opts).run
end
