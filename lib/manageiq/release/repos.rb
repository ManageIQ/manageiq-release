require 'yaml'
require 'pathname'
require 'active_support/core_ext/enumerable'

module ManageIQ
  module Release
    class Repos
      CONFIG_DIR = Pathname.new("../../../config").expand_path(__dir__)

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
        Dir.glob(CONFIG_DIR.join("repos*.yml")).sort.each_with_object({}) do |f, h|
          h.merge!(YAML.load_file(f))
        end
      end
      private_class_method :config
    end
  end
end
