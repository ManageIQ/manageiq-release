#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq/release'
require 'manageiq/release/settings'

require 'aws-sdk-s3'
require 'fileutils'
require 'rubygems'
require 'rubygems/package'
require 'zlib'

gems_to_push = ARGV
raise "Please specify at least one gem" if gems_to_push.empty?

client = Aws::S3::Client.new(
  :access_key_id     => Settings.manageiq_rubygems.s3_access_key,
  :secret_access_key => Settings.manageiq_rubygems.s3_secret_key,
  :region            => "us-east-1",
  :endpoint          => Settings.manageiq_rubygems.s3_endpoint
)

def ungzip(gzip)
  reader = Zlib::GzipReader.new(gzip)
  StringIO.new(reader.read)
ensure
  reader.close
end

def untar(io, destination)
  Gem::Package::TarReader.new(io) do |tar|
    tar.each do |entry|
      destination_file = File.join(destination, entry.full_name)

      if entry.directory?
        FileUtils.mkdir_p(destination_file)
      else
        destination_directory = File.dirname(destination_file)
        FileUtils.mkdir_p(destination_directory) unless File.directory?(destination_directory)
        File.write(destination_file, entry.read)
      end
    end
  end
end

def assemble_index_html(specs_hash)
<<-HTML
<html>
  <body>
    <p>Thanks for visiting rubygems.manageiq.org, we are serving the following gems:</p>
    <ul>
      #{index_html_body(specs_hash)}
    </ul>
  </body>
</html>
HTML
end

def index_html_body(specs_hash)
  array = specs_hash.each_with_object([]) do |(k, v), a|
    a << "      <li><b>#{k}:</b>"
    a << "        <ul>"
    v.sort.each { |i| a << "          <li>v#{i}</li>"}
    a << "        </ul>"
    a << "      </li>"
  end << ""
  array.join("\n").strip
end

require 'tmpdir'
Dir.mktmpdir do |tmpdir|
  puts "Created tempdir at #{tmpdir}"

  puts "Fetching index pack..."
  response = client.get_object(:bucket => Settings.manageiq_rubygems.s3_bucket, :key => 'index.tgz')

  puts "Unpacking index pack..."
  untar(ungzip(response.body), tmpdir)

  gem_dir = File.join(tmpdir, "gems")
  FileUtils.mkdir_p(gem_dir)
  gems_to_push.each { |new_gem| FileUtils.cp(new_gem, gem_dir)}

  puts "Updating rubygems index"
  require "rubygems/indexer"
  Gem::Indexer.new(tmpdir, :build_modern => true).update_index

  puts "Re-generating index pack..."
  tarfile = StringIO.new
  Gem::Package::TarWriter.new(tarfile) do |tar_writer|
    (Dir[File.join(tmpdir, "*specs.4.8")] + Dir[File.join(tmpdir, "quick", "**/*")]).each do |file|
      mode = File.stat(file).mode
      destination = file.split("#{tmpdir}/").last

      if File.directory?(file)
        tar_writer.mkdir destination, mode
      else
        puts "  adding file: #{destination}"
        tar_writer.add_file(destination, mode) do |entry|
          entry.write(File.read(file, :mode => "rb"))
        end
      end
    end
  end

  tarfile.rewind

  Zlib::GzipWriter.open(File.join(tmpdir, "index.tgz")) do |gz|
    gz.write(tarfile.string)
  end

  puts "Uploading files:"
  Dir.glob(File.join(tmpdir, "**/*")).sort.each do |file|
    next if File.directory?(file)

    destination_name = file.split("#{tmpdir}/").last
    puts "  uploading: #{destination_name}"
    File.open(file, 'rb') do |content|
      client.put_object(:bucket => Settings.manageiq_rubygems.s3_bucket, :key => destination_name, :body => content, :acl => "public-read")
    end
  end

  puts "Updating index.html"
  specs_hash = Marshal.load(File.read(File.join(tmpdir, "specs.4.8"))).each_with_object({}) do |i, h|
    name = i[0]
    h[name] ||= []
    h[name] << i[1]
  end
  client.put_object(
    :acl          => "public-read",
    :body         => assemble_index_html(specs_hash),
    :bucket       => Settings.manageiq_rubygems.s3_bucket,
    :content_type => "text/html",
    :key          => "index.html",
  )

  puts "Complete!"
end
