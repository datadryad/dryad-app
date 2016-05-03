require 'spec_helper'

module Stash
  module Sword2
    describe Namespaces do
      it 'defines namespaces' do
        constants = [
            :SWORD,
            :SWORD_TERMS,
            :SWORD_PACKAGE,
            :SWORD_ERROR,
            :SWORD_STATE,
            :ATOM_PUB,
            :ATOM,
            :DC_TERMS,
            :RDF,
            :OAI_ORE
        ]

        prefixes = []
        uris     = []

        constants.each do |c|
          ns = Namespaces.const_get(c)
          expect(ns).to be_an(XML::MappingExtensions::Namespace)

          expect(uris).not_to include(ns.uri)
          uris << ns.uri

          if ns.prefix
            expect(prefixes).not_to include(ns.prefix)
            prefixes << ns.prefix
          end
        end

      end

    end
  end
end
