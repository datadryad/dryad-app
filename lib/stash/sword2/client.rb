
module Stash
  module Sword2
    module Client
      Dir.glob(File.expand_path('../client/*.rb', __FILE__)).sort.each(&method(:require))

      def initialize(helper = HTTPHelper.new(user_agent: "stash-sword2 #{VERSION}"))
        @helper = helper
      end

      def self.new(*args)
        c = Class.new
        c.send(:include, self)
        c.new(*args)
      end

      # Gets the content of the specified URI as a string.
      # @param uri [URI, String] the URI to download
      # @return [String] the content of the URI
      def get(uri)
        @helper.fetch(uri: Sword2.to_uri(uri))
      end
    end
  end
end
