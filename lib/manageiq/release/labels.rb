module ManageIQ
  module Release
    class Labels
      def self.[](repo)
        all[repo]
      end

      def self.all
        @all ||= config["repos"]
      end

      def self.config
        ManageIQ::Release.load_config_file("labels")
      end
      private_class_method :config
    end
  end
end
