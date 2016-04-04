require 'datacite/mapping'
require 'stash/wrapper'
require 'tempfile'
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

        case @resource.resource_type.resource_type
          when "Spreadsheet"
            @type = dm::ResourceTypeGeneral::DATASET
          when "MultipleTypes"
            @type = dm::ResourceTypeGeneral::COLLECTION
          when "Image"
            @type = dm::ResourceTypeGeneral::IMAGE
          when "Sound"
            @type = dm::ResourceTypeGeneral::SOUND
          when "Video"
            @type = dm::ResourceTypeGeneral::AUDIOVISUAL
          when "Text"
            @type = dm::ResourceTypeGeneral::TEXT
          when "Software"
            @type = dm::ResourceTypeGeneral::SOFTWARE
          else
            @type = dm::ResourceTypeGeneral::OTHER
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
        datacite_to_wrapper = resource.save_to_xml
        datacite_root = resource.write_xml
        datacite_target = "#{@resource.id}_datacite.xml"
        datacite_directory = "#{Rails.root}/public/uploads"
        puts Dir.pwd
        f = File.open("#{datacite_directory}/#{datacite_target}", 'w') { |f| f.write(datacite_root) }
        puts datacite_root


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

        embargo = st::Embargo.new(
          type: st::EmbargoType::NONE,
          period: 'none',
          start_date: Date.today,
          end_date: Date.today
        )

        inventory = st::Inventory.new(
          files: [
            st::StashFile.new(
              pathname: 'HSRC_MasterSampleII.dat', size_bytes: 12_345, mime_type: 'text/plain'
            ),
            st::StashFile.new(
              pathname: 'HSRC_MasterSampleII.csv', size_bytes: 67_890, mime_type: 'text/csv'
            ),
            st::StashFile.new(
              pathname: 'HSRC_MasterSampleII.sas7bdat', size_bytes: 123_456, mime_type: 'application/x-sas-data'
            ),
          ])

        wrapper = st::StashWrapper.new(
          identifier: identifier,
          version: version,
          license: license,
          embargo: embargo,
          inventory: inventory,
          descriptive_elements: [datacite_to_wrapper]
        )

        stash_wrapper = wrapper.write_xml
        stash_wrapper_target = "#{@resource.id}_stash_wrapper.xml"
        stash_wrapper_directory = "#{Rails.root}/public/uploads"
        puts Dir.pwd
        f = File.open("#{stash_wrapper_directory}/#{stash_wrapper_target}", 'w') { |f| f.write(stash_wrapper) }
        puts stash_wrapper
      end
    end
  end
end





