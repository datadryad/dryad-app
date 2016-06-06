require 'typesafe_enum'
require 'xml/mapping_extensions'

module Stash
  module Sword
    class Namespace < TypesafeEnum::Base
      NS = XML::MappingExtensions::Namespace
      private_constant(:NS)

      new :SWORD, NS.new(uri: 'http://purl.org/net/sword/')
      new :SWORD_TERMS, NS.new(uri: 'http://purl.org/net/sword/terms/', prefix: 'sword')
      new :SWORD_PACKAGE, NS.new(uri: 'http://purl.org/net/sword/package')
      new :SWORD_ERROR, NS.new(uri: 'http://purl.org/net/sword/error')
      new :SWORD_STATE, NS.new(uri: 'http://purl.org/net/sword/state')
      new :ATOM_PUB, NS.new(uri: 'http://www.w3.org/2007/app', prefix: 'app')
      new :ATOM, NS.new(uri: 'http://www.w3.org/2005/Atom', prefix: 'atom')
      new :DC_TERMS, NS.new(uri: 'http://purl.org/dc/terms/', prefix: 'dcterms')
      new :RDF, NS.new(uri: 'http://www.w3.org/1999/02/22-rdf-syntax-ns#', prefix: 'rdf')
      new :OAI_ORE, NS.new(uri: 'http://www.openarchives.org/ore/terms/', prefix: 'ore')

      def uri
        value.uri
      end

      def prefix
        value.prefix
      end
    end
  end
end
