require 'manageiq/release/repo'
require 'manageiq/release/repos'

require 'manageiq/release/release_tag'
require 'manageiq/release/destroy_tag'

module ManageIQ
  module Release
    HEADER = ("=" * 80).freeze
    SEPARATOR = ("*" * 80).freeze

    def self.header(title)
      title = " #{title} "
      start = (HEADER.length / 2) - (title.length / 2)
      HEADER.dup.tap { |h| h[start, title.length] = title }
    end

    def self.separator
      SEPARATOR
    end

    def self.log_header(title)
      puts header(title)
    end

    def self.log_separator
      puts separator
    end
  end
end
