#!/usr/bin/env ruby
require 'yaml'

file = '.codeclimate.yml'

if File.exists?(file)
  data = YAML.load_file(file)
  version = 'rubocop-0-69'

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
end
