require 'stash/stash-merritt/lib/datacite/mapping/datacite_xml_factory'
require 'nokogiri'

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

      it 'generates funders with funderIdentifiers if contributor has name_identifier_id' do
        @resource.contributors = [] # erase the default funder
        contributor = create(:contributor, resource_id: @resource.id)
        dc_xml_string = @xml_factory.build_datacite_xml
        doc = Nokogiri::XML(dc_xml_string)
        doc.remove_namespaces! # to simplify the xpath expressions for convenience
        x_funder = doc.xpath('//resource/fundingReferences/fundingReference').first

        expect(x_funder.xpath('funderName').to_s).to include(contributor.contributor_name.encode(xml: :text))
        expect(x_funder.xpath('funderIdentifier').to_s).to include('funderIdentifierType="Crossref Funder ID"')
        expect(x_funder.xpath('funderIdentifier').to_s).to include(contributor.name_identifier_id.encode(xml: :text))
        expect(x_funder.xpath('awardNumber').to_s).to include(contributor.award_number.encode(xml: :text))
      end

      it 'leaves out funderIdentifier if contributor has blank name_identifier_id' do
        @resource.contributors = [] # erase the default funder
        contributor = create(:contributor, resource_id: @resource.id, name_identifier_id: nil)
        dc_xml_string = @xml_factory.build_datacite_xml
        doc = Nokogiri::XML(dc_xml_string)
        doc.remove_namespaces! # to simplify the xpath expressions for convenience
        x_funder = doc.xpath('//resource/fundingReferences/fundingReference').first

        expect(x_funder.xpath('funderName').to_s).to include(contributor.contributor_name.encode(xml: :text))
        expect(x_funder.xpath('funderIdentifier').to_s).to be_blank
        expect(x_funder.xpath('awardNumber').to_s).to include(contributor.award_number.encode(xml: :text))
      end

      describe 'datacite xml factory with builder that checks actual XML' do
        it 'sets the resourceTypeGeneral' do
          builder = Stash::Merritt::Builders::MerrittDataciteBuilder.new(@xml_factory)
          contents = builder.contents
          doc = Nokogiri::XML(contents)
          doc.remove_namespaces! # to simplify the xpath expressions for convenience
          expect(doc.xpath('//resourceType/@resourceTypeGeneral').first.value).to eq('Dataset')
        end

        it 'sets the correct issued and available dates' do
          @resource.update(publication_date: Time.utc(2018, 1, 1), meta_view: true)
          @res2 = create(:resource, identifier: @resource.identifier, meta_view: true, file_view: true, publication_date: Time.utc(2018, 2, 1))
          @res3 = create(:resource, identifier: @resource.identifier, meta_view: true, file_view: true, publication_date: Time.utc(2018, 3, 1))

          @xml_factory = DataciteXMLFactory.new(
            se_resource_id: @res3.id,
            doi_value: @resource.identifier.identifier,
            total_size_bytes: 1234,
            version: 3
          )

          builder = Stash::Merritt::Builders::MerrittDataciteBuilder.new(@xml_factory)
          contents = builder.contents
          doc = Nokogiri::XML(contents)
          doc.remove_namespaces! # to simplify the xpath expressions for convenience
          expect(doc.xpath("//dates/date[@dateType = 'Issued']").first.child.text).to start_with('2018-01-01')
          expect(doc.xpath("//dates/date[@dateType = 'Available']").first.child.text).to start_with('2018-02-01')
        end

        it 'adds subjects to XML with the scheme and uri if available' do
          subj_entry = create(:subject, subject: 'My Test Subject', subject_scheme: 'LCSH', scheme_URI: 'http://id.loc.gov/authorities/subjects')
          @resource.subjects << subj_entry

          builder = Stash::Merritt::Builders::MerrittDataciteBuilder.new(@xml_factory)
          contents = builder.contents
          doc = Nokogiri::XML(contents)
          doc.remove_namespaces! # to simplify the xpath expressions for convenience
          expect(doc.xpath("//subjects/subject[@subjectScheme = 'fos']").first.child.text).to eql(@resource.subjects.first.subject)
          expect(doc.xpath("//subjects/subject[@subjectScheme = 'LCSH']").first.child.text).to eql('My Test Subject')
        end

        it 'adds author ROR affiliations to XML' do
          builder = Stash::Merritt::Builders::MerrittDataciteBuilder.new(@xml_factory)
          contents = builder.contents
          doc = Nokogiri::XML(contents)
          doc.remove_namespaces! # to simplify the xpath expressions for convenience
          expect(doc.xpath('//creators/creator/affiliation').first.child.to_s).to eql(@resource.authors.first.affiliation.long_name)
          expect(doc.xpath('//creators/creator/affiliation[@affiliationIdentifier]').first.attributes['affiliationIdentifier'].value).to \
            eql(@resource.authors.first.affiliation.ror_id)
          expect(doc.xpath('//creators/creator/affiliation[@affiliationIdentifier]').first.attributes['affiliationIdentifierScheme'].value)
            .to eql('ROR')
        end

        it 'adds funding affiliations to XML' do
          builder = Stash::Merritt::Builders::MerrittDataciteBuilder.new(@xml_factory)
          contents = builder.contents
          doc = Nokogiri::XML(contents)
          doc.remove_namespaces! # to simplify the xpath expressions for convenience
          expect(doc.xpath('//fundingReferences//fundingReference/funderName').first.text)
            .to eql(@resource.contributors.where(contributor_type: 'funder').first.contributor_name)
          expect(doc.xpath('//fundingReferences//fundingReference/funderIdentifier').first.text)
            .to eql(@resource.contributors.where(contributor_type: 'funder').first.name_identifier_id)
          expect(doc.xpath('//fundingReferences//fundingReference/funderIdentifier').first.attributes['funderIdentifierType'].value)
            .to eql('Crossref Funder ID')
        end
      end
    end
  end
end
