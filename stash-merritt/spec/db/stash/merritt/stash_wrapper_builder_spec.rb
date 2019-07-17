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

        describe 'validate' do
          attr_reader :builder
          attr_reader :logger

          before(:each) do
            @builder = StashWrapperBuilder.new(
              dcs_resource: dc4_resource,
              version_number: 1,
              uploads: []
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
