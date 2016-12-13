module StashDatacite
  module Resource
    class DublinCoreBuilder
      ROOT_ATTRIBUTES = {
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:noNamespaceSchemaLocation' => 'http://dublincore.org/schemas/xmls/qdc/2008/02/11/qualifieddc.xsd',
        'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
        'xmlns:dcterms' => 'http://purl.org/dc/terms/'
      }.freeze

      attr_reader :resource
      attr_reader :tenant

      def initialize(resource:, tenant:)
        @resource = resource
        @tenant = tenant
      end

      def build_xml_string
        xml_builder = Nokogiri::XML::Builder.new do |xml|
          xml.qualifieddc(ROOT_ATTRIBUTES) do
            add_creators(xml)
            add_contributors(xml)
            add_title(xml)
            add_publisher(xml)
            add_pub_year(xml)
            add_subjects(xml)
            add_resource_type(xml)
            add_rights(xml)
            add_descriptions(xml)
            add_related_identifiers(xml)
          end
        end
        xml_builder.to_xml.to_s
      end

      private

      def add_creators(xml)
        resource.creators.each do |c|
          xml.send(:'dc:creator', c.creator_full_name.delete("\r").to_s)
        end
      end

      def add_pub_year(xml)
        pub_year = resource.publication_years.first
        xml.send(:'dc:date', pub_year.publication_year) if pub_year
      end

      def add_publisher(xml)
        # TODO: should we just leave dc:publisher out if it's not present, or is it required, & if so by what?
        xml.send(:'dc:publisher', (tenant.short_name || tenant.long_name || 'unknown').to_s)
      end

      def add_title(xml)
        # TODO: is this right? or should we add all titles?
        xml.send(:'dc:title', resource.titles.where(title_type: nil).first.title.to_s)
      end

      def add_contributors(xml)
        # Funder contributors are handled under 'add_descriptions' below
        resource.contributors.where.not(contributor_type: 'funder').each do |c|
          if (contrib_name = c.contributor_name) && !contrib_name.blank?
            xml.send(:'dc:contributor', contrib_name.strip)
          end
        end
      end

      def add_subjects(xml)
        resource.subjects.each do |s|
          xml.send(:'dc:subject', s.subject.delete("\r").to_s)
        end
      end

      def add_resource_type(xml)
        resource_type = (rt = resource.resource_type) && rt.resource_type_general
        xml.send(:'dc:type', resource_type.strip) unless resource_type.blank?
      end

      def add_rights(xml)
        resource.rights.each do |r|
          xml.send(:'dc:rights', r.rights.to_s)
          xml.send(:'dcterms:license', r.rights_uri.to_s, 'xsi:type' => 'dcterms:URI')
        end
      end

      def add_descriptions(xml)
        unless resource.descriptions.blank? # TODO: what is this check for?
          resource.descriptions.each do |d|
            desc_text = d.description.to_s.delete("\r")
            xml.send(:'dc:description', desc_text.to_s) unless desc_text.blank?
          end
        end
        resource.contributors.where(contributor_type: 'funder').each do |c|
          contrib_name = c.contributor_name
          award_num = c.award_number
          desc_text = 'Data were created'
          desc_text << " with funding from #{contrib_name}" unless contrib_name.blank?
          desc_text << " under grant(s) #{award_num}" unless award_num.blank?
          xml.send(:'dc:description', desc_text)
        end
      end

      def add_related_identifiers(xml)
        resource.related_identifiers.each do |r|
          case r.relation_type_friendly
          when 'IsPartOf'
            xml.send(:'dcterms:isPartOf', r.related_identifier_type_friendly.to_s + ': ' + r.related_identifier.to_s)
          when 'HasPart'
            xml.send(:'dcterms:hasPart', r.related_identifier_type_friendly.to_s + ': ' + r.related_identifier.to_s)
          when 'IsCitedBy'
            xml.send(:'dcterms:isReferencedBy', r.related_identifier_type_friendly.to_s + ': ' + r.related_identifier.to_s)
          when 'Cites'
            xml.send(:'dcterms:references', r.related_identifier_type_friendly.to_s + ': ' + r.related_identifier.to_s)
          when 'IsReferencedBy'
            xml.send(:'dcterms:isReferencedBy', r.related_identifier_type_friendly.to_s + ': ' + r.related_identifier.to_s)
          when 'References'
            xml.send(:'dcterms:references', r.related_identifier_type_friendly.to_s + ': ' + r.related_identifier.to_s)
          when 'IsNewVersionOf'
            xml.send(:'dcterms:isVersionOf', r.related_identifier_type_friendly.to_s + ': ' + r.related_identifier.to_s)
          when 'IsPreviousVersionOf'
            xml.send(:'dcterms:hasVersion', r.related_identifier_type_friendly.to_s + ': ' + r.related_identifier.to_s)
          when 'IsVariantFormOf'
            xml.send(:'dcterms:isVersionOf', r.related_identifier_type_friendly.to_s + ': ' + r.related_identifier.to_s)
          when 'IsOriginalFormOf'
            xml.send(:'dcterms:hasVersion', r.related_identifier_type_friendly.to_s + ': ' + r.related_identifier.to_s)
          else
            xml.send(:'dcterms:relation', r.related_identifier_type_friendly.to_s + ': ' + r.related_identifier.to_s)
          end
        end
      end
    end
  end
end
