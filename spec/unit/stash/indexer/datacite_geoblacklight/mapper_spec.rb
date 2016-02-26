require 'spec_helper'

module Stash
  module Indexer
    module DataciteGeoblacklight
      describe Mapper do
        describe '#to_index_document' do
          DM = Datacite::Mapping
          SW = Stash::Wrapper

          before(:each) do

            @doi_value = '10.14749/1407399498'
            @default_title = 'An Account of a Very Odd Monstrous Calf'
            @creator_names = ['Hedy Lamarr', 'Herschlag, Natalie']
            @resource_type_value = 'Other'
            @subjects = [
              'Assessment',
              'Information Literacy',
              'Engineering',
              'Undergraduate Students',
              'CELT',
              'Purdue University'
            ]
            @places = {
              'Hogwarts' => DM::GeoLocationPoint.new(57.1267878,-3.8796586),
              'Uagadou' => DM::GeoLocationPoint.new(0.3127848,29.7234399),
              'Ilvermorny' => DM::GeoLocationPoint.new(46.2992002,-74.0356198),
              'Castelobruxo' => DM::GeoLocationPoint.new(-8.1466343,-60.3444434)
            }
            locations = @places.map { |plc, pt| DM::GeoLocation.new(place: plc, point: pt) }

            id = DM::Identifier.new(value: @doi_value)
            creators = [
              DM::Creator.new(
                name: @creator_names[0],
                identifier: DM::NameIdentifier.new(scheme: 'ISNI', scheme_uri: URI('http://isni.org/'), value: '0000-0001-1690-159X'),
                affiliations: ['United Artists', 'Metro-Goldwyn-Mayer']
              ),
              DM::Creator.new(
                name: @creator_names[1],
                identifier: DM::NameIdentifier.new(scheme: 'ISNI', scheme_uri: URI('http://isni.org/'), value: '0000-0001-0907-8419'),
                affiliations: ['Gaumont Buena Vista International', '20th Century Fox']
              )
            ]
            titles = [
              DM::Title.new(value: @default_title, language: 'en-emodeng'),
              DM::Title.new(type: DM::TitleType::SUBTITLE, value: 'And a Contest between Two Artists about Optick Glasses, &c', language: 'en-emodeng')
            ]
            publisher = 'California Digital Library'
            pub_year = 2015

            resource = DM::Resource.new(
              identifier: id,
              creators: creators,
              titles: titles,
              publisher: publisher,
              publication_year: pub_year,
              resource_type: DM::ResourceType.new(resource_type_general: DM::ResourceTypeGeneral::DATASET, value: @resource_type_value),
              subjects: @subjects.map { |s| DM::Subject.new(value: s) },
              geo_locations: locations
            )

            payload_xml = resource.save_to_xml

            wrapper = SW::StashWrapper.new(
              identifier: SW::Identifier.new(type: SW::IdentifierType::DOI, value: @doi_value),
              version: SW::Version.new(number: 1, date: Date.new(2013, 8, 18), note: 'Sample wrapped Datacite document'),
              license: SW::License::CC_BY,
              embargo: SW::Embargo.new(type: SW::EmbargoType::DOWNLOAD, period: '1 year', start_date: Date.new(2014, 8, 18), end_date: Date.new(2013, 8, 18)),
              inventory: SW::Inventory.new(
                files: [
                  SW::StashFile.new(pathname: 'HSRC_MasterSampleII.dat', size_bytes: 12_345, mime_type: 'text/plain'),
                  SW::StashFile.new(pathname: 'HSRC_MasterSampleII.csv', size_bytes: 67_890, mime_type: 'text/csv'),
                  SW::StashFile.new(pathname: 'HSRC_MasterSampleII.sas7bdat', size_bytes: 123_456, mime_type: 'application/x-sas-data'),
                  SW::StashFile.new(pathname: 'formats.sas7bcat', size_bytes: 78_910, mime_type: 'application/x-sas-catalog'),
                  SW::StashFile.new(pathname: 'HSRC_MasterSampleII.sas', size_bytes: 11_121, mime_type: 'application/x-sas'),
                  SW::StashFile.new(pathname: 'HSRC_MasterSampleII.sav', size_bytes: 31_415, mime_type: 'application/x-sav'),
                  SW::StashFile.new(pathname: 'HSRC_MasterSampleII.sps', size_bytes: 16_171, mime_type: 'application/x-spss'),
                  SW::StashFile.new(pathname: 'HSRC_MasterSampleII.dta', size_bytes: 81_920, mime_type: 'application/x-dta'),
                  SW::StashFile.new(pathname: 'HSRC_MasterSampleII.dct', size_bytes: 212_223, mime_type: 'application/x-dct'),
                  SW::StashFile.new(pathname: 'HSRC_MasterSampleII.do', size_bytes: 242_526, mime_type: 'application/x-do')
                ]),
              descriptive_elements: [payload_xml]
            )

            @index_document = Mapper.new.to_index_document(wrapper)
          end

          it 'extracts the identifier' do
            expect(@index_document[:dc_identifier_s]).to eq(@doi_value)
          end

          it 'extracts the title' do
            expect(@index_document[:dc_title_s]).to eq(@default_title)
          end

          it 'extracts the creator names' do
            expect(@index_document[:dc_creator_sm]).to eq(@creator_names)
          end

          it 'extracts the resource type' do
            expect(@index_document[:dc_type_s]).to eq(@resource_type_value)
          end

          it 'extracts the subjects' do
            expect(@index_document[:dc_subject_sm]).to eq(@subjects)
          end

          it 'extracts the places' do
            expect(@index_document[:dct_spatial_sm]).to eq(@places.keys)
          end

          it 'extracts the bounding boxes'
          it 'extracts the points'
          it "doesn't extract points from places"
          it 'extracts the issue date'
          it 'extracts the rights'
          it 'extracts the publisher'
        end
      end
    end
  end
end

# dct_issued_dt should be: Time.utc(d.year, d.month, d.day).xmlschema
