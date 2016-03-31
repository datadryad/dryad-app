require 'datacite/mapping'
require 'stash/wrapper'

module StashDatacite
  module Resource
    class ResourceFileGeneration
      def initialize(resource, current_tenant)
        @resource = resource
        @current_tenant = current_tenant
      end

      def generate_xml
        dm = Datacite::Mapping
        st = Stash::Wrapper


        if @resource.resource_type.resource_type == "Spreadsheet"
          @type = dm::ResourceTypeGeneral::DATASET
        elsif @resource.resource_type.resource_type == "MultipleTypes"
          @type = dm::ResourceTypeGeneral::COLLECTION
        else
          @type = @resource.resource_type.resource_type
        end
        # # Based on "Example for a simple dataset"
        # # http://schema.datacite.org/meta/kernel-3/example/datacite-example-dataset-v3.0.xml

        resource = dm::Resource.new(
          identifier: dm::Identifier.new(value: '10.5072/D3P26Q35R-Test'),

          creators: @resource.creators.map do |creator|
            dm::Creator.new(name: "#{creator.creator_full_name}")
          end,

          titles: [
              dm::Title.new(value: "#{@resource.titles.where(title_type: :main).first.title}")
          ],

          publisher: "#{@current_tenant.long_name || 'unknown'}",

          publication_year: Time.now.year,

          subjects: @resource.subjects.map do |subject|
            dm::Subject.new(value: "#{subject.subject}")
          end,

          language: 'en',

          resource_type: dm::ResourceType.new(resource_type_general: @type, value: "#{@resource.resource_type.resource_type}" ),

          version: '1',

          descriptions: [
            dm::Description.new(
                type: dm::DescriptionType::ABSTRACT,
                value: "#{@resource.descriptions.where(description_type: :abstract).first.description}"
            ),
            dm::Description.new(
                type: dm::DescriptionType::METHODS,
                value: "#{@resource.descriptions.where(description_type: :methods).first.description}"
            ),
            dm::Description.new(
                type: dm::DescriptionType::OTHER,
                value: "#{@resource.descriptions.where(description_type: :usage_notes).first.description}"
            )
          ]
        )

        datacite_root = resource.save_to_xml

        identifier = st::Identifier.new(
          type: st::IdentifierType::DOI,
          value: '10.14749/1407399498'
        )

        version = st::Version.new(
          number: 1,
          date: Date.new(2013, 8, 18),
          note: 'Sample wrapped Datacite document'
        )

        license = st::License::CC_BY

        wrapper = st::StashWrapper.new(
          identifier: identifier,
          version: version,
          license: license,
          embargo: embargo,
          inventory: inventory,
          descriptive_elements: [datacite_root]
        )

        puts wrapper.write_xml
      end
    end
  end
end
