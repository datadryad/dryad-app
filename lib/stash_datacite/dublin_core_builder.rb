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
          xml.qualifieddc(ROOT_ATTRIBUTES) {
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
          }
        end
        xml_builder.to_xml.to_s
      end

      private

      def add_creators(xml)
        resource.creators.each do |c|
          xml.send(:'dc:creator', "#{c.creator_full_name.gsub(/\r/, '')}")
        end
      end

      def add_pub_year(xml)
        pub_year = resource.publication_years.first
        if pub_year
          xml.send(:'dc:date', pub_year.publication_year)
        end
      end

      def add_publisher(xml)
        # TODO: should we just leave dc:publisher out if it's not present, or is it required, & if so by what?
        xml.send(:'dc:publisher', "#{tenant.long_name || 'unknown'}")
      end

      def add_title(xml)
        # TODO: is this right? or should we add all titles?
        xml.send(:'dc:title', "#{resource.titles.where(title_type: nil).first.title}")
      end

      def add_contributors(xml)
        resource.contributors.each do |c|
          xml.send(:'dc:contributor', "#{c.contributor_name.gsub(/\r/, '')}") unless c.try(:contributor_name).blank?
          xml.send(:'dc:description', "#{c.award_number.gsub(/\r/, '')}") unless c.try(:award_number).blank?
        end
      end

      def add_subjects(xml)
        resource.subjects.each do |s|
          xml.send(:'dc:subject', "#{s.subject.gsub(/\r/, '')}")
        end
      end

      def add_resource_type(xml)
        # TODO: do we only want the general type, or do we want the specific type?
        xml.send(:'dc:type', "#{resource.resource_type.resource_type}")
      end

      def add_rights(xml)
        resource.rights.each do |r|
          xml.send(:'dc:rights', "#{r.rights}")
          xml.send(:'dcterms:license', "#{r.rights_uri}", 'xsi:type' => 'dcterms:URI')
        end
      end

      def add_descriptions(xml)
        unless resource.descriptions.blank? # TODO: what is this check for?
          resource.descriptions.each do |d|
            desc_text = d.description.to_s.gsub(/\r/, '')
            xml.send(:'dc:description', "#{desc_text}") unless desc_text.blank?
          end
        end
      end

      def add_related_identifiers(xml)
        resource.related_identifiers.each do |r|
          case r.relation_type_friendly
            when 'IsPartOf'
              xml.send(:'dcterms:isPartOf', "#{r.related_identifier_type_friendly}" + ': ' + "#{r.related_identifier}")
            when 'HasPart'
              xml.send(:'dcterms:hasPart', "#{r.related_identifier_type_friendly}" + ': ' + "#{r.related_identifier}")
            when 'IsCitedBy'
              xml.send(:'dcterms:isReferencedBy', "#{r.related_identifier_type_friendly}" + ': ' + "#{r.related_identifier}")
            when 'Cites'
              xml.send(:'dcterms:references', "#{r.related_identifier_type_friendly}" + ': ' + "#{r.related_identifier}")
            when 'IsReferencedBy'
              xml.send(:'dcterms:isReferencedBy', "#{r.related_identifier_type_friendly}" + ': ' + "#{r.related_identifier}")
            when 'References'
              xml.send(:'dcterms:references', "#{r.related_identifier_type_friendly}" + ': ' + "#{r.related_identifier}")
            when 'IsNewVersionOf'
              xml.send(:'dcterms:isVersionOf', "#{r.related_identifier_type_friendly}" + ': ' + "#{r.related_identifier}")
            when 'IsPreviousVersionOf'
              xml.send(:'dcterms:hasVersion', "#{r.related_identifier_type_friendly}" + ': ' + "#{r.related_identifier}")
            when 'IsVariantFormOf'
              xml.send(:'dcterms:isVersionOf', "#{r.related_identifier_type_friendly}" + ': ' + "#{r.related_identifier}")
            when 'IsOriginalFormOf'
              xml.send(:'dcterms:hasVersion', "#{r.related_identifier_type_friendly}" + ': ' + "#{r.related_identifier}")
            else
              xml.send(:'dcterms:relation', "#{r.related_identifier_type_friendly}" + ': ' + "#{r.related_identifier}")
          end
        end
      end
    end
  end
end
