
module Stash
  module Sword2
    module Client
      Dir.glob(File.expand_path('../client/*.rb', __FILE__)).sort.each(&method(:require))

      def initialize(helper: HTTPHelper.new(user_agent: "stash-sword2 #{VERSION}"))
        @helper = helper
      end

      def self.new(*args)
        c = Class.new
        c.send(:include, self)
        c.new(*args)
      end


    end
  end
end
