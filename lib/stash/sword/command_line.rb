require_relative 'options'

module Stash
  module Sword
    class CommandLine

      def self.exec(argv, &block)
        options = Options.new(argv)
        if options.show_help
          puts Options::USAGE
        else
          begin
            client = Client.new(username: options.username, password: options.password, on_behalf_of: options.on_behalf_of)
            yield client, options
          rescue => e
            puts e
            puts Options::USAGE
          end
        end
      end

    end
  end
end
