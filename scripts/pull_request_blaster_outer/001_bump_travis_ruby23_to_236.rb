#! /usr/bin/env ruby

# We're run from the repo's directory
require 'yaml'

travis = "#{Dir.pwd}/.travis.yml"
yml = YAML.load_file(travis)
yml["rvm"].reject! {|r| r.start_with?("2.3")}
yml["rvm"].unshift("2.3.6")

File.open(travis, 'w') do |file|
  file.write(YAML.dump(yml).sub("---\n", ""))
end
