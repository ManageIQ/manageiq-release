module ManageIQ
  module Release
    class Github
      def self.create_or_update_repository_secret(repo_name, key, value)
        payload = encode_secret(repo_name, value)
        github.create_or_update_secret(repo_name, key, payload)
      end

      private_class_method def self.encode_secret(repo_name, value)
        require "rbnacl"
        require "base64"

        repo_public_key = github.get_public_key(repo_name)
        decoded_repo_public_key = Base64.decode64(repo_public_key.key)
        public_key = RbNaCl::PublicKey.new(decoded_repo_public_key)
        box = RbNaCl::Boxes::Sealed.from_public_key(public_key)
        encrypted_value = box.encrypt(value)
        encoded_encrypted_value = Base64.strict_encode64(encrypted_value)

        {
          "encrypted_value" => encoded_encrypted_value,
          "key_id"          => repo_public_key.key_id
        }
      end

      private_class_method def self.github
        ManageIQ::Release.github
      end
    end
  end
end

