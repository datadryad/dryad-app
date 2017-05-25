require 'db_spec_helper'

module Stash
  module Merritt
    module Builders
      describe StashWrapperBuilder do
        attr_reader :dc4_resource

        before(:each) do
          tmp_wrapper_xml = File.read('spec/data/archive/stash-wrapper.xml')
          tmp_wrapper = Stash::Wrapper::StashWrapper.parse_xml(tmp_wrapper_xml)
          dc4_xml = tmp_wrapper.stash_descriptive[0]
          @dc4_resource = Datacite::Mapping::Resource.parse_xml(dc4_xml)
        end

        describe 'embargo' do
          it 'defaults to NONE' do
            builder = StashWrapperBuilder.new(
              dcs_resource: dc4_resource,
              version_number: 1,
              uploads: [],
              embargo_end_date: nil
            )
            wrapper_xml = builder.contents
            wrapper = Stash::Wrapper::StashWrapper.parse_xml(wrapper_xml)
            embargo = wrapper.embargo

            none = Stash::Wrapper::Embargo.none
            %i[type period start_date end_date].each do |field|
              expect(embargo.send(field)).to eq(none.send(field))
            end
          end

          it 'accepts an end date' do
            embargo_end_date = Date.new(1952, 2, 6)

            builder = StashWrapperBuilder.new(
              dcs_resource: dc4_resource,
              version_number: 1,
              uploads: [],
              embargo_end_date: embargo_end_date
            )
            wrapper_xml = builder.contents
            wrapper = Stash::Wrapper::StashWrapper.parse_xml(wrapper_xml)
            embargo = wrapper.embargo

            expect(embargo.type).to eq(Stash::Wrapper::EmbargoType::DOWNLOAD)
            expect(embargo.end_date).to eq(embargo_end_date)
            expect(embargo.start_date).to be <= embargo.end_date
          end

          it 'accepts a non-UTC end date' do
            embargo_end_date = Date.new(2122, 2, 6)

            builder = StashWrapperBuilder.new(
              dcs_resource: dc4_resource,
              version_number: 1,
              uploads: [],
              embargo_end_date: embargo_end_date
            )
            wrapper_xml = builder.contents
            wrapper = Stash::Wrapper::StashWrapper.parse_xml(wrapper_xml)
            embargo = wrapper.embargo

            expect(embargo.type).to eq(Stash::Wrapper::EmbargoType::DOWNLOAD)
            expect(embargo.end_date).to eq(embargo_end_date)
            expect(embargo.start_date).to be <= embargo.end_date
          end

          it 'accepts a UTC time' do
            embargo_end_time = Time.now.utc
            expected_end_date = embargo_end_time.to_date

            builder = StashWrapperBuilder.new(
              dcs_resource: dc4_resource,
              version_number: 1,
              uploads: [],
              embargo_end_date: embargo_end_time
            )
            wrapper_xml = builder.contents
            wrapper = Stash::Wrapper::StashWrapper.parse_xml(wrapper_xml)
            embargo = wrapper.embargo

            expect(embargo.type).to eq(Stash::Wrapper::EmbargoType::DOWNLOAD)
            expect(embargo.end_date).to eq(expected_end_date)
            expect(embargo.start_date).to be <= embargo.end_date
          end

          it 'converts a non-UTC time to UTC date' do
            embargo_end_time = Time.new(2020, 1, 1, 0, 0, 1, '+12:45')
            expected_end_date = Date.new(2019, 12, 31)

            builder = StashWrapperBuilder.new(
              dcs_resource: dc4_resource,
              version_number: 1,
              uploads: [],
              embargo_end_date: embargo_end_time
            )
            wrapper_xml = builder.contents
            wrapper = Stash::Wrapper::StashWrapper.parse_xml(wrapper_xml)
            embargo = wrapper.embargo

            expect(embargo.type).to eq(Stash::Wrapper::EmbargoType::DOWNLOAD)
            expect(embargo.end_date).to eq(expected_end_date)
            expect(embargo.start_date).to be <= embargo.end_date
          end

          it 'rejects a non-date' do
            expect do
              StashWrapperBuilder.new(
                dcs_resource: dc4_resource,
                version_number: 1,
                uploads: [],
                embargo_end_date: Time.now.xmlschema
              )
            end.to raise_error(ArgumentError)
          end
        end

        describe 'validate' do
          attr_reader :builder
          attr_reader :logger

          before(:each) do
            @builder = StashWrapperBuilder.new(
              dcs_resource: dc4_resource,
              version_number: 1,
              uploads: [],
              embargo_end_date: nil
            )

            def builder.do_validate?
              true
            end

            @logger = instance_double(Logger)
            allow(Rails).to receive(:logger).and_return(logger)
          end

          after(:each) do
            allow(Rails).to receive(:logger).and_call_original
          end

          it 'validates the XML' do
            xml = builder.build_xml
            expect(logger).not_to receive(:error)
            builder.validate(xml)
          end

          it 'raises for invalid XML' do
            xml = File.read('spec/data/bad-stash-wrapper.xml')
            allow(logger).to receive(:error) do |e|
              expect(e).to include('bad_xml')
            end
            expect { builder.validate(xml) }.to raise_error(Nokogiri::XML::SyntaxError)
          end
        end
      end
    end
  end
end
