require 'spec_helper'

module Stash
  module Sword2
    describe Namespace do

      it 'defines namespaces' do
        by_namespace = {}
        by_uri     = {}
        by_prefix = {}

        Namespace.each do |ns_enum|
          expect(ns_enum.value).to be_an(XML::MappingExtensions::Namespace)

          expect(by_namespace.key?(ns_enum.value)).to be(false), "Duplicate namespace: #{by_namespace[ns_enum.value]} and #{ns_enum} both declare #{ns_enum.value}"
          by_namespace[ns_enum.value] = ns_enum

          expect(by_uri.key?(ns_enum.uri)).to be(false), "Duplicate URI: #{by_uri[ns_enum.uri]} and #{ns_enum} both declare #{ns_enum.uri}"
          by_uri[ns_enum.uri] = ns_enum

          if ns_enum.prefix
            expect(by_prefix.key?(ns_enum.prefix)).to be(false), "Duplicate prefix: #{by_prefix[ns_enum.prefix]} and #{ns_enum} both declare #{ns_enum.prefix}"
            by_prefix[ns_enum.prefix] = ns_enum
          end
        end

      end

    end
  end
end
