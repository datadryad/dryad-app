module Stash
  module Sword2
    module Client
      Dir.glob(File.expand_path('../client/*.rb', __FILE__)).sort.each(&method(:require))

      attr_reader :username
      attr_reader :password
      attr_reader :on_behalf_of

      def initialize(username:, password:, on_behalf_of: nil, helper: nil)
        fail 'no username provided' unless username
        fail 'no password provided' unless password
        @username = username
        @password = password
        @on_behalf_of = on_behalf_of || username
        @helper = helper || HTTPHelper.new(username: username, password: password, user_agent: "stash-sword2 #{VERSION}")
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
