#!/usr/bin/env ruby

# Usage: SPACES_KEY=my_key SPACES_SECRET=my_secret VAGRANT_USERNAME=my_user VAGRANT_PASSWORD=my_password bin/sync_vagrant_builds.rb

##### Find vagrant builds from releases.manageiq.org #####

def format_key(key)
  @string_size = [@string_size.to_i, key.length + 2].max
  key.ljust(@string_size, " ")
end

def s3_client
  @client ||= begin
    require 'aws-sdk-s3'
    Aws::S3::Client.new(:access_key_id => ENV['SPACES_KEY'], :secret_access_key => ENV['SPACES_SECRET'], :endpoint => "https://nyc3.digitaloceanspaces.com", :region => 'us-east-1')
  end
end

bucket            = "releases-manageiq-org"
releases_versions = {}
start_time        = Time.now.utc.to_i

puts "Syncing vagrant builds..."

s3_client.list_objects_v2(:bucket => bucket, :prefix => "manageiq-vagrant-").flat_map { |r| r.contents }.each do |obj|
  next if obj.key.match(/manageiq-vagrant-\w+-\d{8}.box/) # Skip nightly builds
  next if obj.key == "manageiq-vagrant-devel.box"
  object = s3_client.head_object(:bucket => bucket, :key => obj.key)
  _manageiq, _vagrant, version_name, minor_patch, suffix = obj.key[0...-4].split("-", 5)
  minor, patch = minor_patch.to_s.split(".", 2)
  vagrant_version = "#{version_name[0].ord - 96}.#{minor}.#{patch || 0}"
  vagrant_version << "-#{suffix}" if suffix
  releases_versions[version_name] ||= {}
  releases_versions[version_name][vagrant_version] ||= {}
  releases_versions[version_name][vagrant_version][:key] = obj.key
  releases_versions[version_name][vagrant_version][:md5] = object.etag[1...-1] # For some reason this is quoted
end


##### Register vagrant builds on vagrantup.com #####

def check_response!(response, object_name)
  if response.status.success?
    puts " - Created #{object_name}"
  else
    puts " - Failed to create #{object_name}"
    exit 1
  end
end

def vagrant_client
  require "http"
  HTTP.persistent("https://app.vagrantup.com").headers("Content-Type" => "application/json", "Authorization" => "Bearer #{vagrant_token}")
end

def vagrant_token
  @vagrant_token ||= begin
    api = HTTP.persistent("https://app.vagrantup.com").headers("Content-Type" => "application/json")
    response = api.post("/api/v1/authenticate", json: {  token: { description: "Build registration script" },  user: { login: ENV["VAGRANT_USERNAME"], password: ENV["VAGRANT_PASSWORD"] }})
    token = JSON.parse(response.body)["token"]
    if !response.status.success? || !token
      puts "Failed to log in!"
      exit 1
    end

    puts "Logged in!"
    token
  end
end

releases_versions.each do |name, version_hash|
  response = vagrant_client.get("/api/v1/box/manageiq/#{name}")
  print "#{name} : "
  if response.status.success?
    puts "Found"
  else
    print "Attempting to create..."
    response = vagrant_client.post("/api/v1/boxes", json: {box: {username: "manageiq", name: name, short_description: "ManageIQ Open-Source Management Platform https://manageiq.org", is_private: false}})
    check_response!(response, "major version")
  end

  version_hash.each do |version, info|
    print "- #{version} : "
    response = vagrant_client.get("/api/v1/box/manageiq/#{name}/version/#{version}")
    if response.status == 200
      puts "exists"
      next
    else
      puts "missing, attempting to register..."
      response = vagrant_client.post("/api/v1/box/manageiq/#{name}/versions", json: {version: {version: version, description: "#{info[:key].match(/manageiq-vagrant-(.*)\.box/)[1]} release"}})
      check_response!(response, "version")

      response = vagrant_client.post("/api/v1/box/manageiq/#{name}/version/#{version}/providers", json: {provider: {name: "virtualbox", url: "https://releases.manageiq.org/#{info[:key]}", checksum: info[:md5], checksum_type: "md5"}})
      check_response!(response, "provider")

      response = vagrant_client.put("/api/v1/box/manageiq/#{name}/version/#{version}/release")
      check_response!(response, "release")
    end
  end
end

puts "Completed in #{Time.now.utc.to_i - start_time} seconds."
