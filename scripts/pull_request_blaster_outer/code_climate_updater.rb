#!/usr/bin/env ruby
require 'yaml'

file = '.codeclimate.yml'
version = 'rubocop-0-69' # Update as needed

unless File.exist?(file)
  puts "#{file} doesn't exist, skipping"
  exit 0
end

data = YAML.load_file(file)

# Most ManageIQ repositories
if data['engines'] && data['engines']['rubocop']
  unless data['engines']['rubocop']['channel'] && data['engines']['rubocop']['channel'] == version
    data['engines']['rubocop']['channel'] = version
  end
end

# Toplogical inventory, et al
if data['plugins'] && data['plugins']['rubocop']
  unless data['plugins']['rubocop']['channel'] && data['plugins']['rubocop']['channel'] == version
    data['plugins']['rubocop']['channel'] = version
  end
end

File.open(file, 'w'){ |fh| YAML.dump(data, fh) }
