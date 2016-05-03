require 'xml/mapping_extensions'

module Stash
  module Sword2
    module Namespaces
      NS = XML::MappingExtensions::Namespace
      private_constant(:NS)

      SWORD         = NS.new(uri: 'http://purl.org/net/sword/')
      SWORD_TERMS   = NS.new(uri: 'http://purl.org/net/sword/terms/', prefix: 'sword')
      SWORD_PACKAGE = NS.new(uri: 'http://purl.org/net/sword/package')
      SWORD_ERROR   = NS.new(uri: 'http://purl.org/net/sword/error')
      SWORD_STATE   = NS.new(uri: 'http://purl.org/net/sword/state')
      ATOM_PUB      = NS.new(uri: 'http://www.w3.org/2007/app', prefix: 'app')
      ATOM          = NS.new(uri: 'http://www.w3.org/2005/Atom', prefix: 'atom')
      DC_TERMS      = NS.new(uri: 'http://purl.org/dc/terms/', prefix: 'dcterms')
      RDF           = NS.new(uri: 'http://www.w3.org/1999/02/22-rdf-syntax-ns#', prefix: 'rdf')
      OAI_ORE       = NS.new(uri: 'http://www.openarchives.org/ore/terms/', prefix: 'ore')
    end
  end
end
