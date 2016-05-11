module Stash
  module Sword2
    module Client
      Dir.glob(File.expand_path('../client/*.rb', __FILE__)).sort.each(&method(:require))

      attr_reader :username
      attr_reader :password
      attr_reader :on_behalf_of

      def initialize(username:, password:, on_behalf_of: nil, helper: nil)
        raise 'no username provided' unless username
        raise 'no password provided' unless password
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

      def create(collection_uri:, slug:, zipfile:)
        # states
        # - submitted (and waiting for response)
        # - error (bad status code, summary)

        # TODO: how to process asynchronously

        # TODO: do a POST
      end

      def update(edit_iri:, slug:, zipfile:)
        # states
        # - submitted (and waiting for response)
        # - error (bad status code, summary)

        # TODO: how to process asynchronously

        # TODO: do a PUT
      end

    end
  end
end
