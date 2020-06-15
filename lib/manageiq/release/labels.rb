module ManageIQ
  module Release
    class Labels
      def self.[](repo)
        all[repo]
      end

      def self.all
        @all ||= begin
          config["orgs"].each do |org, options|
            ManageIQ::Release.github_repo_names_for(org).each do |repo_name|
              next if config.key_path?("repos", repo_name)
              next if options["except"].include?(repo_name)
              config.store_path("repos", repo_name, options["labels"])
            end
          end
          config["repos"].sort.to_h
        end
      end

      def self.config
        @config ||= ManageIQ::Release.load_config_file("labels")
      end
      private_class_method :config
    end
  end
end
