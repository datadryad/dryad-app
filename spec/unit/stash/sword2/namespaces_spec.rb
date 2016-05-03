require 'spec_helper'

module Stash
  module Sword2
    describe Namespaces do

      it 'defines namespaces' do
        by_namespace = {}
        by_uri     = {}
        by_prefix = {}

        Namespaces.constants.each do |c|
          ns = Namespaces.const_get(c)
          expect(ns).to be_an(XML::MappingExtensions::Namespace)

          expect(by_namespace.key?(ns)).to be(false), "Duplicate namespace: #{by_namespace[ns]} and #{c} both declare #{ns}"
          by_namespace[ns] = c

          expect(by_uri.key?(ns.uri)).to be(false), "Duplicate URI: #{by_uri[ns.uri]} and #{c} both declare #{ns.uri}"
          by_uri[ns.uri] = c

          if ns.prefix
            expect(by_prefix.key?(ns.prefix)).to be(false), "Duplicate prefix: #{by_prefix[ns.prefix]} and #{c} both declare #{ns.prefix}"
            by_prefix[ns.prefix] = c
          end
        end

      end

    end
  end
end
