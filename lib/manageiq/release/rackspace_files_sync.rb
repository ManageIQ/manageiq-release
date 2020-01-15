require 'json'
require 'restclient'

module ManageIQ
  module Release
    class RackspaceFilesSync
      def initialize(options)
        @options = options
        @source_directory = options[:source]
      end

      def sync
        login

        files = destination_files.dup

        source_files.each do |source|
          destination = source.split(@source_directory).last
          destination = destination[1..-1]
          destination_hash = files.delete(destination)
          next if File.directory?(source)

          source_hash = Digest::MD5.file(source).hexdigest
          if source_hash != destination_hash
            puts "#{destination_hash.nil? ? 'Uploading' : 'Replacing'} #{destination}"
            upload_file(source, destination, source_hash)
          else
            puts "Found     #{destination}"
          end
        end

        return unless @options[:delete]

        files.each_key do |destination|
          puts "Deleting  #{destination}"
          delete_file(destination)
        end
      end

      private

      def delete_file(destination)
        RestClient.delete(url(destination), {"X-Auth-Token" => @access_token})
      end

      def upload_file(source, destination, source_hash)
        RestClient.put(
          url(destination),
          File.read(source),
          {
            "X-Auth-Token"          => @access_token,
            "X-Detect-Content-Type" => "True",
            "ETag"                  => source_hash,
          }
        )
      end

      def url(file = nil)
        parts = [@public_url, @options[:destination]]
        parts << URI.encode(file) if file
        parts.join("/")
      end

      def login
        login_response = RestClient.post(
          "https://identity.api.rackspacecloud.com/v2.0/tokens",
          {
            "auth" => {
              "RAX-KSKEY:apiKeyCredentials" => {
                "username" => ENV["RACKSPACE_USERNAME"],
                "apiKey"   => ENV["RACKSPACE_API_KEY"]
              }
            }
          }.to_json,
          {:content_type => :json}
        )

        parsed_login_response = JSON.parse(login_response.body)
        @access_token         = parsed_login_response["access"]["token"]["id"]
        @public_url           = parsed_login_response["access"]["serviceCatalog"].detect { |i| i["name"] == "cloudFiles" }["endpoints"].detect { |i| i["region"] == "IAD" }["publicURL"]
      end

      def destination_files
        @destination_files ||= begin
          destination_files_response = RestClient.get(url, {:accept => :json, "X-Auth-Token" => @access_token})
          parsed_destination_files = JSON.parse(destination_files_response.body)
          parsed_destination_files.each_with_object({}) do |meta, hash|
            hash[meta["name"]] = meta["hash"]
          end
        end
      end

      def source_files
        @source_files ||= Dir.glob(File.join(@source_directory, "**/*"))
      end
    end
  end
end
