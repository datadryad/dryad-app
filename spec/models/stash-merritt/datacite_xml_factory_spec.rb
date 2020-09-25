require 'stash/stash-merritt/lib/datacite/mapping/datacite_xml_factory'

module Datacite
  module Mapping
    describe DataciteXMLFactory do

      before(:each) do
        total_size_bytes = 3_286_679

        @dc4_xml = File.read('spec/data/archive/mrt-datacite.xml')
        @dcs_resource = Datacite::Mapping::Resource.parse_xml(@dc4_xml)

        user = create(:user,
                      first_name: 'Lisa',
                      last_name: 'Muckenhaupt',
                      email: 'lmuckenhaupt@example.edu',
                      tenant_id: 'dataone')

        @resource = create(:resource,
                           user: user,
                           tenant_id: 'dataone')

        @xml_factory = DataciteXMLFactory.new(
          se_resource_id: @resource.id,
          doi_value: @resource.identifier.identifier,
          total_size_bytes: total_size_bytes,
          version: 1
        )
      end

      it 'generates DC3' do
        # Should look like spec/data/dc3.xml
        actual_string = @xml_factory.build_datacite_xml(datacite_3: true)
        actual = Hash.from_xml(actual_string)['resource']

        expect(actual['xmlns']).to eq('http://datacite.org/schema/kernel-3')
        expect(actual['titles']['title']).to eq(@resource.title)
        expect(actual['identifier']).to eq(@resource.identifier.identifier)
        expect(actual['publicationYear']).to eq(@resource.publication_date.year.to_s)
        expect(actual['creators']['creator']['creatorName']).to eq(@resource.authors.first.author_full_name)
        expect(actual['creators']['creator']['nameIdentifier']).to eq(@resource.authors.first.author_orcid)
      end

      it 'generates DC4' do
        # Should look like spec/data/dc4-with-funding-references.xml
        actual_string = @xml_factory.build_datacite_xml
        actual = Hash.from_xml(actual_string)['resource']

        expect(actual['xmlns']).to eq('http://datacite.org/schema/kernel-4')
        expect(actual['titles']['title']).to eq(@resource.title)
        expect(actual['identifier']).to eq(@resource.identifier.identifier)
        expect(actual['publicationYear']).to eq(@resource.publication_date.year.to_s)
        expect(actual['creators']['creator']['creatorName']).to eq(@resource.authors.first.author_full_name)
        expect(actual['creators']['creator']['nameIdentifier']).to eq(@resource.authors.first.author_orcid)
      end

      it 'defaults missing resource_type to DATASET' do
        @resource.resource_type = nil
        @resource.save!

        dcs_resource = @xml_factory.build_resource
        resource_type = dcs_resource.resource_type
        expect(resource_type).not_to be_nil
        expect(resource_type.resource_type_general).to be(ResourceTypeGeneral::DATASET)
      end

      it 'creates FOS Science subject in the way DataCite requested' do
        subject = create(:subject, subject_scheme: 'fos')
        @resource.subjects << subject
        @resource.save!

        dcs_resource = @xml_factory.build_resource
        subjs = dcs_resource.subjects.map(&:value)
        expect(subjs).to include("FOS: #{subject.subject}")
      end
    end
  end
end
