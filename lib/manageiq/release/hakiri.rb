module ManageIQ
  module Release
    class Hakiri
      def self.badge_details(repo, branch)
        {
          "description" => "Security",
          "image"       => "https://hakiri.io/github/#{repo.github_repo}/#{branch}.svg",
          "url"         => "https://hakiri.io/github/#{repo.github_repo}/#{branch}"
        }
      end

      attr_reader :repo

      def initialize(repo, **_)
        @repo = repo
      end

      def badge_details
        self.class.badge_details(repo, "master")
      end
    end
  end
end
