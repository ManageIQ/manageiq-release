#! /usr/bin/env ruby
require 'yaml'

if `grep -E 'git clone.+manageiq.git' bin/setup`.include?('manageiq.git')
  if File.exist?(File.join(Dir.pwd, 'bin/setup'))

    travis = File.join(Dir.pwd, '.travis.yml')
    unless File.exist?(travis)
      puts "#{travis} doesn't exist, skipping"
      exit 0
    end

    travis_content = File.read(travis)
    changed = false
    changed = true if travis_content.gsub!(/2\.[0-9].[0-9]+/, '2.5.3')

    yaml = YAML.safe_load(travis_content)

    if yaml['rvm']
      yaml['rvm'].length > 1 ? yaml['rvm'] = [yaml['rvm'][0]] : yaml.delete('matrix')
      changed = true
    end

    if changed
      File.write(travis, yaml.to_yaml)
      puts "Wrote updated travis.yml at: #{travis}"
    end
  end
end
