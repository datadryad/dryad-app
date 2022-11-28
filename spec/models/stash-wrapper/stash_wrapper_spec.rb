require 'nokogiri'
require 'rexml/element'

module Stash
  module Wrapper
    describe StashWrapper do
      describe 'stash_wrapper.xsd' do
        it 'is valid' do
          schema = Nokogiri::XML::Schema(File.read('spec/data/wrapper/stash_wrapper.xsd'))
          document = Nokogiri::XML(File.read('spec/data/wrapper/wrapper-1.xml'))
          errors = schema.validate(document)
          expect(errors.empty?).to be true
        end

        it 'validates a document' do
          schema = Nokogiri::XML::Schema(File.read('spec/data/wrapper/stash_wrapper.xsd'))
          document = Nokogiri::XML(File.read('spec/data/wrapper/wrapper-2.xml'))
          errors = schema.validate(document)
          errors.each do |e|
            puts e
          end
          expect(errors.empty?).to be true
        end
      end

      describe '#parse_xml' do
        it 'parses an XML file' do
          data = File.read('spec/data/wrapper/wrapper-1.xml')
          wrapper = StashWrapper.parse_xml(data)

          id = wrapper.identifier
          expect(id.type).to eq(IdentifierType::DOI)
          expect(id.value).to eq('10.12345/1234567890')

          admin = wrapper.stash_administrative

          version = admin.version
          expect(version.version_number).to eq(1)
          expect(version.date).to eq(Date.new(2015, 9, 8))

          license = admin.license
          expect(license.name).to eq('Creative Commons Attribution 4.0 International (CC BY 4.0)')
          expect(license.uri).to eq(URI('https://creativecommons.org/licenses/by/4.0/'))

          embargo = admin.embargo
          expect(embargo.type).to eq(EmbargoType::DOWNLOAD)
          expect(embargo.period).to eq('6 months')
          expect(embargo.start_date).to eq(Date.new(2015, 9, 8))
          expect(embargo.end_date).to eq(Date.new(2016, 3, 7))

          inventory = admin.inventory
          expect(inventory.num_files).to eq(1)
          expect(inventory.files.size).to eq(1)

          file = inventory.files[0]
          expect(file.pathname).to eq('mydata.xlsx')
          expect(file.size_bytes).to eq(12_345_678)
          expect(file.mime_type).to eq(MIME::Type.new('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'))

          descriptive = wrapper.stash_descriptive
          expect(descriptive).to be_an(Array)
          expect(descriptive.size).to eq(1)
          desc_elem = descriptive[0]
          expect(desc_elem).to be_an(REXML::Element)

          expected_xml =
            '<dcs:resource xmlns:dcs="http://datacite.org/schema/kernel-3"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xsi:schemaLocation="http://datacite.org/schema/kernel-3 http://schema.datacite.org/meta/kernel-3/metadata.xsd">
              <dcs:identifier identifierType="DOI">10.12345/1234567890</dcs:identifier>
              <dcs:creators>
                <dcs:creator>
                  <dcs:creatorName>Abrams, Stephen</dcs:creatorName>
                </dcs:creator>
              </dcs:creators>
              <dcs:titles>
                <dcs:title>My dataset</dcs:title>
              </dcs:titles>
              <dcs:publisher>UC Office of the President</dcs:publisher>
              <dcs:publicationYear>2016</dcs:publicationYear>
              <dcs:subjects>
                <dcs:subject>Data literacy</dcs:subject>
              </dcs:subjects>
              <dcs:resourceType resourceTypeGeneral="Dataset">Spreadsheet</dcs:resourceType>
              <dcs:descriptions>
                <dcs:description descriptionType="Abstract">Lorum ipsum.</dcs:description>
              </dcs:descriptions>
            </dcs:resource>'

          now = Time.now.to_i
          path = 'dcs.xml'
          FileUtils.mkdir('tmp') unless File.directory?('tmp')
          File.write("tmp/#{now}-expected-#{path}", expected_xml)
          File.write("tmp/#{now}-actual-#{path}", desc_elem)

          expect(desc_elem).to be_xml(expected_xml)
        end

        it 'reads a Merritt OAI response' do
          xml_str = File.read('spec/data/wrapper/mrtoai-wrapper.xml')
          wrapper = StashWrapper.parse_xml(xml_str)

          expect(wrapper.id_value).to eq('10.21271/wxy1000199')
          expect(wrapper.version_number).to eq(1)
          expect(wrapper.version_date).to eq(Date.new(2012, 8, 17))
          expect(wrapper.license_name).to eq('Creative Commons Attribution 4.0 International (CC BY 4.0)')
          expect(wrapper.license_uri).to eq(URI('https://creativecommons.org/licenses/by/4.0/'))
        end

        it 'works with the old (cdlib.org) schema location' do
          xml_str_old_schema_location = File.read('spec/data/wrapper/mrtoai-wrapper-old-schema-location.xml')
          expect(xml_str_old_schema_location).not_to include('ucop.edu') # just to be sure

          wrapper = StashWrapper.parse_xml(xml_str_old_schema_location)
          roundtrip_xml = wrapper.write_xml

          xml_str_new_schema_location = File.read('spec/data/wrapper/mrtoai-wrapper.xml')
          expect(xml_str_new_schema_location).not_to include('cdlib.org') # just to be sure
          expect(roundtrip_xml).to be_xml(xml_str_new_schema_location)
        end
      end

      describe '#initialize' do

        attr_reader :params

        before(:each) do
          @params = {
            identifier: Identifier.new(type: IdentifierType::DOI, value: '10.14749/1407399498'),
            version: Version.new(number: 1, date: Date.new(2013, 8, 18), note: 'Sample wrapped Datacite document'),
            license: License::CC_BY,
            inventory: Inventory.new(
              files: [
                StashFile.new(pathname: 'HSRC_MasterSampleII.dat', size_bytes: 12_345, mime_type: 'text/plain')
              ]
            ),
            descriptive_elements: []
          }
        end

        it 'requires an identifier' do
          params.delete(:identifier)
          expect { StashWrapper.new(**params) }.to raise_error(ArgumentError)
        end

        it 'requires a valid identifier' do
          params[:identifier] = 'doi:10.14749/1407399498'
          expect { StashWrapper.new(**params) }.to raise_error(ArgumentError)
        end

        it 'requires a version' do
          params.delete(:version)
          expect { StashWrapper.new(**params) }.to raise_error(ArgumentError)
        end

        it 'requires a valid version' do
          params[:version] = 1
          expect { StashWrapper.new(**params) }.to raise_error(ArgumentError)

          params[:version] = '1'
          expect { StashWrapper.new(**params) }.to raise_error(ArgumentError)
        end

        it 'requires a license' do
          params.delete(:license)
          expect { StashWrapper.new(**params) }.to raise_error(ArgumentError)
        end

        it 'requires a valid license' do
          params[:license] = 'CC-BY'
          expect { StashWrapper.new(**params) }.to raise_error(ArgumentError)
        end
      end

      describe 'convenience accessors' do
        it 'evades the law of Demeter' do
          data = File.read('spec/data/wrapper/wrapper-1.xml')
          wrapper = StashWrapper.parse_xml(data)

          expect(wrapper.id_value).to eq('10.12345/1234567890')
          expect(wrapper.id_type).to eq(IdentifierType::DOI)
          expect(wrapper.version_number).to eq(1)
          expect(wrapper.version_date).to eq(Date.new(2015, 9, 8))
          expect(wrapper.license_name).to eq('Creative Commons Attribution 4.0 International (CC BY 4.0)')
          expect(wrapper.license_uri).to eq(URI('https://creativecommons.org/licenses/by/4.0/'))

          inventory = wrapper.inventory
          expect(inventory.num_files).to eq(1)
          expect(inventory.files.size).to eq(1)
          file = inventory.files[0]
          expect(file.pathname).to eq('mydata.xlsx')
          expect(file.size_bytes).to eq(12_345_678)
          expect(file.mime_type).to eq(MIME::Type.new('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'))
        end

        describe '#file_names' do
          it 'lists the file names' do
            data = File.read('spec/data/wrapper/wrapper-2.xml')
            wrapper = StashWrapper.parse_xml(data)

            expected = %w[
              HSRC_MasterSampleII.dat
              HSRC_MasterSampleII.csv
              HSRC_MasterSampleII.sas7bdat
              formats.sas7bcat
              HSRC_MasterSampleII.sas
              HSRC_MasterSampleII.sav
              HSRC_MasterSampleII.sps
              HSRC_MasterSampleII.dta
              HSRC_MasterSampleII.dct
              HSRC_MasterSampleII.do
            ]
            expect(wrapper.file_names).to eq(expected)
          end

          it 'returns an empty array for an empty inventory' do
            wrapper = StashWrapper.new(
              identifier: Identifier.new(type: IdentifierType::DOI, value: '10.14749/1407399498'),
              version: Version.new(number: 1, date: Date.new(2013, 8, 18), note: 'Sample wrapped Datacite document'),
              license: License::CC_BY,
              descriptive_elements: []
            )
            expect(wrapper.file_names).to eq([])
          end
        end
      end

      describe '#save_to_xml' do

        describe 'namespace handling' do
          before :each do
            wrapper = StashWrapper.new(
              identifier: Identifier.new(type: IdentifierType::DOI, value: '10.14749/1407399498'),
              version: Version.new(number: 1, date: Date.new(2013, 8, 18), note: 'Sample wrapped Datacite document'),
              license: License::CC_BY,
              inventory: Inventory.new(
                files: [
                  StashFile.new(pathname: 'HSRC_MasterSampleII.dat', size_bytes: 12_345, mime_type: 'text/plain')
                ]
              ),
              # NOTE: the recursive asserts only work because descriptive_elements is empty
              descriptive_elements: []
            )
            @wrapper_xml = wrapper.save_to_xml
          end

          it 'sets the correct namespace' do
            assert_st = ->(elem) do
              actual = elem.namespace
              expected = 'https://dash.ucop.edu/stash_wrapper/'
              expect(actual).to eq(expected), "expected '#{expected}', got '#{actual}': #{elem}"
              elem.each_element { |e| assert_st.call(e) }
            end
            assert_st.call(@wrapper_xml.root)
          end

          it 'sets the correct namespace prefix' do
            assert_st = ->(elem) do
              actual = elem.prefix
              expected = 'st'
              expect(actual).to eq(expected), "expected '#{expected}', got '#{actual}': #{elem}"
              elem.each_element { |e| assert_st.call(e) }
            end
            assert_st.call(@wrapper_xml.root)
          end

          it 'maps the namespace to the prefix' do
            assert_st = ->(elem) do
              actual = elem.namespace('st')
              expected = 'https://dash.ucop.edu/stash_wrapper/'
              expect(actual).to eq(expected), "expected '#{expected}', got '#{actual}': #{elem}"
              elem.each_element { |e| assert_st.call(e) }
            end
            assert_st.call(@wrapper_xml.root)
          end

          it 'includes the prefix in the name' do
            assert_st = ->(elem) do
              expect(elem.to_s).to start_with('<st:')
              elem.each_element { |e| assert_st.call(e) }
            end
            assert_st.call(@wrapper_xml.root)
          end
        end

        it 'maps to XML' do

          payload = File.read('spec/data/wrapper/wrapper-2-payload.xml')
          payload_xml = REXML::Document.new(payload).root

          wrapper = StashWrapper.new(
            identifier: Identifier.new(type: IdentifierType::DOI, value: '10.14749/1407399498'),
            version: Version.new(number: 1, date: Date.new(2013, 8, 18), note: 'Sample wrapped Datacite document'),
            license: License::CC_BY,
            inventory: Inventory.new(
              files: [
                StashFile.new(pathname: 'HSRC_MasterSampleII.dat', size_bytes: 12_345, mime_type: 'text/plain'),
                StashFile.new(pathname: 'HSRC_MasterSampleII.csv', size_bytes: 67_890, mime_type: 'text/csv'),
                StashFile.new(pathname: 'HSRC_MasterSampleII.sas7bdat', size_bytes: 123_456, mime_type: 'application/x-sas-data'),
                StashFile.new(pathname: 'formats.sas7bcat', size_bytes: 78_910, mime_type: 'application/x-sas-catalog'),
                StashFile.new(pathname: 'HSRC_MasterSampleII.sas', size_bytes: 11_121, mime_type: 'application/x-sas'),
                StashFile.new(pathname: 'HSRC_MasterSampleII.sav', size_bytes: 31_415, mime_type: 'application/x-sav'),
                StashFile.new(pathname: 'HSRC_MasterSampleII.sps', size_bytes: 16_171, mime_type: 'application/x-spss'),
                StashFile.new(pathname: 'HSRC_MasterSampleII.dta', size_bytes: 81_920, mime_type: 'application/x-dta'),
                StashFile.new(pathname: 'HSRC_MasterSampleII.dct', size_bytes: 212_223, mime_type: 'application/x-dct'),
                StashFile.new(pathname: 'HSRC_MasterSampleII.do', size_bytes: 242_526, mime_type: 'application/x-do')
              ]
            ),
            descriptive_elements: [payload_xml]
          )

          wrapper_xml = wrapper.save_to_xml

          puts wrapper_xml

          # File.open('spec/data/wrapper/wrapper-2-actual.xml', 'w') do |file|
          #   formatter = REXML::Formatters::Pretty.new
          #   formatter.width = 200
          #   formatter.compact = true
          #   file.write(formatter.write(wrapper_xml, ''))
          # end

          r = %r{<st:embargo>.+</st:embargo>}m

          # ignore the embargo which is no longer used in stash wrapper for Merritt
          expected_xml = File.read('spec/data/wrapper/wrapper-2.xml').gsub(r, '')
          expect(wrapper_xml.to_s.gsub(r, '')).to be_xml(expected_xml)
        end
      end

    end
  end
end
