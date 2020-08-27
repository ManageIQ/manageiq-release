require 'yaml'
require 'active_support/core_ext/enumerable'

module ManageIQ
  module Release
    class RepoSet
      def self.[](branch)
        all[branch]
      end

      def self.all
        @all ||=
          config.each_with_object({}) do |(branch, repos), h|
            h[branch] = repos.map { |name, options| Repo.new(name, options) }
          end
      end

      def self.all_repos
        all.values.flatten.index_by(&:name).values
      end

      def self.config
        @config ||= ManageIQ::Release.load_config_file("repos")
      end
      private_class_method :config
    end
  end
end
