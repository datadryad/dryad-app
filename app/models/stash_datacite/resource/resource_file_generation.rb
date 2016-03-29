require 'datacite/mapping'
module StashDatacite
  module Resource
    class ResourceFileGeneration
      def initialize(resource)
        @resource = resource
      end

      @reviewed_resource = Resource::Review.new(@resource)

      dm = Datacite::Mapping
      # Based on "Example for a simple dataset"
      # http://schema.datacite.org/meta/kernel-3/example/datacite-example-dataset-v3.0.xml
      resource = dm::Resource.new(
          identifier: dm::Identifier.new(value: '10.5072/D3P26Q35R-Test'),
          creators: [
              # dm::Creator.new(name: 'Fosmirer, Michael'),
              # dm::Creator.new(name: 'Wertz, Ruth'),
              # dm::Creator.new(name: 'Purzer, Senay')
          ],
          titles: [
              dm::Title.new(value: @reviewed_resource.title)
          ],
          publisher: @reviewed_resource.user.affliation,
          publication_year: Time.now.year,
          subjects: [
              # dm::Subject.new(value: 'Assessment'),
              # dm::Subject.new(value: 'Information Literacy'),
              # dm::Subject.new(value: 'Engineering'),
              # dm::Subject.new(value: 'Undergraduate Students'),
              # dm::Subject.new(value: 'CELT'),
              # dm::Subject.new(value: 'Purdue University')
          ],
          language: 'en',
          resource_type: dm::ResourceType.new(resource_type_general: @reviewed_resource.resource_type),
          version: '1',
          descriptions: [
              # dm::Description.new(
              #     type: dm::DescriptionType::ABSTRACT,
              #     value: 'We developed an instrument, Critical Engineering Literacy Test
              #       (CELT), which is a multiple choice instrument designed to
              #       measure undergraduate students’ scientific and information
              #       literacy skills. It requires students to first read a
              #       technical memo and, based on the memo’s arguments, answer
              #       eight multiple choice and six open-ended response questions.
              #       We collected data from 143 first-year engineering students and
              #       conducted an item analysis. The KR-20 reliability of the
              #       instrument was .39. Item difficulties ranged between .17 to
              #       .83. The results indicate low reliability index but acceptable
              #       levels of item difficulties and item discrimination indices.
              #       Students were most challenged when answering items measuring
              #       scientific and mathematical literacy (i.e., identifying
              #       incorrect information).'
              # )
          ]
      )
      resource.save_to_xml
      # puts resource.write_xml
    end
  end
end