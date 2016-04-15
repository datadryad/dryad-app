require 'optparse'

module Stash
  module Sword
    class Options

      def self.init_opts(options)
        OptionParser.new do |opts|
          opts.on('-h', '--help', 'display this help and exit') { options.show_help = true }
          opts.on('-u', '--username USERNAME', 'submit as user USERNAME') { |username| options.username = username }
          opts.on('-p', '--password PASSWORD', 'submit with password PASSWORD') { |password| options.password = password }
          opts.on('-o', '--on-behalf-of OTHER', 'submit on behalf of user OTHER') { |on_behalf_of| options.on_behalf_of = on_behalf_of }
          opts.on('-z', '--zipfile ZIPFILE', 'submit zipfile ZIPFILE') { |zipfile| options.zipfile = zipfile }
          opts.on('-d', '--doi DOI', 'submit with doi DOI') { |doi| options.doi = doi }
          opts.on('-c', '--collection-uri URI', 'submit to collection uri URI') { |collection_uri| options.collection_uri = collection_uri }
          opts.on('-e', '--edit-iri EDIT_IRI', 'submit to Edit-Iri EDIT_IRI') { |edit_iri| options.edit_iri = edit_iri }
        end
      end

      USAGE = "#{init_opts(nil)}\n".freeze

      attr_accessor :show_help
      attr_accessor :username
      attr_accessor :password
      attr_accessor :on_behalf_of
      attr_accessor :zipfile
      attr_accessor :doi
      attr_accessor :collection_uri
      attr_accessor :edit_iri

      def initialize(argv = nil)
        @opt_parser = self.class.init_opts(self)
        @opt_parser.parse(argv)
      end

    end
  end
end
