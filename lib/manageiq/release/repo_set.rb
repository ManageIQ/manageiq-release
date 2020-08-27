require 'yaml'
require 'active_support/core_ext/enumerable'

module ManageIQ
  module Release
    class RepoSet
      def self.[](set_name)
        all[set_name]
      end

      def self.all
        @all ||=
          config.each_with_object({}) do |(set_name, repos), h|
            h[set_name] = repos.map { |name, options| Repo.new(name, options) }.sort_by(&:github_repo)
          end
      end

      def self.config
        @config ||= ManageIQ::Release.load_config_file("repos")
      end
      private_class_method :config
    end
  end
end
