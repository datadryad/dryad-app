require 'stash/repo/file_builder'
require 'action_controller'

module Stash
  module Merritt
    module Builders
      class MerrittOAIDCBuilder < Stash::Repo::FileBuilder
        ROOT_ATTRIBUTES = {
          'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
          'xsi:noNamespaceSchemaLocation' => 'http://dublincore.org/schemas/xmls/qdc/2008/02/11/qualifieddc.xsd',
          'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
          'xmlns:dcterms' => 'http://purl.org/dc/terms/'
        }.freeze

        DC_RELATION_TYPES = {
          'cites' => 'references',
          'iscitedby' => 'isReferencedBy',
          'isnewversionof' => 'isVersionOf',
          'ispreviousversionof' => 'hasVersion',
          'ispartof' => 'isPartOf',
          'haspart' => 'hasPart'
        }.freeze

        attr_reader :resource_id

        def initialize(resource_id:)
          super(file_name: 'mrt-oaidc.xml')
          @resource_id = resource_id
        end

        def mime_type
          MIME::Types['text/xml'].first
        end

        def contents
          Nokogiri::XML::Builder.new do |xml|
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
          end.to_xml.to_s
        end

        private

        def resource
          @resource ||= StashEngine::Resource.find(resource_id)
        end

        def tenant
          resource.tenant
        end

        def add_creators(xml)
          resource.authors.each { |c| xml.send(:'dc:creator', c.author_full_name.delete("\r").to_s) }
        end

        def add_pub_year(xml)
          pub_year = resource.publication_years.first
          xml.send(:'dc:date', pub_year.publication_year) if pub_year
        end

        def add_publisher(xml)
          xml.send(:'dc:publisher', (tenant.short_name || tenant.long_name || 'unknown').to_s)
        end

        def add_title(xml)
          xml.send(:'dc:title', resource.title)
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
          resource.subjects.non_fos.each { |s| xml.send(:'dc:subject', s.subject.delete("\r").to_s) }
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
          strip_desc_linefeeds(xml)
          resource.contributors.where(contributor_type: 'funder').each do |c|
            xml.send(:'dc:description', to_dc_description(c))
          end
        end

        def to_dc_description(contributor)
          contrib_name = contributor.contributor_name
          award_num = contributor.award_number
          desc_text = 'Data were created'
          desc_text << " with funding from #{contrib_name}" unless contrib_name.blank?
          desc_text << " under grant(s) #{award_num}" unless award_num.blank?
        end

        def strip_desc_linefeeds(xml)
          resource.descriptions.each do |d|
            desc_text = ActionController::Base.helpers.strip_tags(d.description.to_s).delete("\r") # gsub(/(\r\n?|\n)/, '')
            xml.send(:'dc:description', desc_text.to_s) unless desc_text.blank?
          end
        end

        def add_related_identifiers(xml)
          resource.related_identifiers.each do |r|
            dc_relation_type = DC_RELATION_TYPES[r.relation_type] || 'relation'
            xml.send(:"dcterms:#{dc_relation_type}", "#{r.related_identifier_type_friendly}: #{r.related_identifier}")
          end
        end
      end
    end
  end
end
