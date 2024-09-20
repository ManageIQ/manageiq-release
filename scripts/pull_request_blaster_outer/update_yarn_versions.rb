#! /usr/bin/env ruby

ENV["YARN_VERSION"] ||= "berry"

def system!(cmd)
  puts "** #{cmd}"
  system(cmd).tap do
    exit $?.exitstatus unless $?.success?
  end
end

# Repository changes
if File.exist?(".yarnrc.yml")
  system!("yarn set version #{ENV.fetch("YARN_VERSION")}")
  FileUtils.rm_f("yarn.lock") if ENV["RM_YARN_LOCK"]
  system!("yarn install")
end

# Plugin generator changes
plugin_dir = "lib/generators/manageiq/plugin/templates"
if Dir.exist?(plugin_dir)
  yarnrc = File.join(plugin_dir, ".yarnrc.yml")
  package_json = File.join(plugin_dir, "package.json")
  yarn_release = File.join(plugin_dir, ".yarn/releases/yarn-*.cjs")

  # Temporarily modify the yarnrc.yaml to remove the dynamic version
  old_yarn_version = Dir.glob(yarn_release).first.match(/yarn-(.+).cjs/).captures.first
  File.write(yarnrc, File.read(yarnrc).sub("<%= yarn_version %>", old_yarn_version))

  # Update yarn
  Dir.chdir(plugin_dir) do
    system!("yarn set version #{ENV.fetch("YARN_VERSION")}")
  end

  # Put back the dynamic version in the yarnrc.yml and package.json
  system!("git checkout -- #{yarnrc} #{package_json}")
end
