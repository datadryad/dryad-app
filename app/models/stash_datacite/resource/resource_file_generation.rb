require 'datacite/mapping'
module StashDatacite
  module Resource
    class ResourceFileGeneration
      def initialize(resource)
        @resource = resource
      end

      def generate_xml
        dm = Datacite::Mapping
        # # Based on "Example for a simple dataset"
        # # http://schema.datacite.org/meta/kernel-3/example/datacite-example-dataset-v3.0.xml

        resource = dm::Resource.new(
            identifier: dm::Identifier.new(value: '10.5072/D3P26Q35R-Test'),

            creators: @resource.creators.map do |creator|
              dm::Creator.new(name: "#{creator.creator_full_name}")
            end,

            titles: [
                dm::Title.new(value: "#{@resource.titles.where(title_type: :main).first}")
            ],

            publisher: 'UCOP', # no such thing as user.affiliation, maybe something off Tenant?
            # publisher: "#{@resource.user.affliation}",
            publication_year: Time.now.year,
            subjects: @resource.subjects.map do |subject|
              dm::Subject.new(value: "#{subject.subject}")
            end,
            language: 'en',
            resource_type: dm::ResourceType.new(resource_type_general: dm::ResourceTypeGeneral::DATASET, value: "#{@resource.resource_type.resource_type}" ),
            version: '1',
            descriptions: [
                dm::Description.new(
                    type: dm::DescriptionType::ABSTRACT,
                    value: "#{@resource.descriptions.where(description_type: :abstract).first.description}"
                )
            ]
        )
        resource.save_to_xml
        # # puts resource.write_xml
      end
    end
  end
end
