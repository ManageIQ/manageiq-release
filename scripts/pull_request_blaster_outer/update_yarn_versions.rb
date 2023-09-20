#! /usr/bin/env ruby

ENV["YARN_VERSION"] ||= "berry"

def system!(cmd)
  puts "** #{cmd}"
  system(cmd).tap do
    exit $?.exitstatus unless $?.success?
  end
end

if File.exist?(".yarnrc.yml")
  system!("yarn set version #{ENV.fetch("YARN_VERSION")}")
  FileUtils.rm_f("yarn.lock") if ENV["RM_YARN_LOCK"]
  system!("yarn install")
end
