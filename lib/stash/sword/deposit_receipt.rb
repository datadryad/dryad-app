require 'xml/mapping_extensions'
require 'stash/sword/namespace'

module Stash
  module Sword

    class Link
      include ::XML::Mapping

      text_node :rel, '@rel'
      uri_node :href, '@href'
      mime_type_node :type, '@type', default_value: nil
    end

    class DepositReceipt
      include ::XML::MappingExtensions::Namespaced

      root_element_name 'entry'
      namespace Namespace::ATOM.value

      array_node :links, 'link', class: Link, default_value: []

      def link(rel:)
        rel = rel.to_s if rel
        links.find { |l| l.rel == rel }
      end

      def em_iri
        em_iri = link(rel: 'edit-media')
        em_iri.href if em_iri
      end

      def edit_iri
        edit_iri = link(rel: 'edit')
        edit_iri.href if edit_iri
      end

      def se_iri
        se_iri = link(rel: URI('http://purl.org/net/sword/terms/add'))
        se_iri.href if em_iri
      end
    end
  end
end
