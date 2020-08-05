require 'spec_helper'

module Stash
  module Merritt
    module Builders
      describe MerrittDataciteBuilder do
        attr_reader :dc4_xml
        attr_reader :resource
        attr_reader :factory
        attr_reader :builder

        before(:each) do
          @dc4_xml = File.read('spec/data/stash-merritt/mrt-datacite.xml')
          @resource = Datacite::Mapping::Resource.parse_xml(dc4_xml)
          @factory = instance_double(Datacite::Mapping::DataciteXMLFactory)
          @builder = MerrittDataciteBuilder.new(factory)
        end

        describe :build_xml do
          it 'builds the XML' do
            allow(factory).to receive(:build_resource).and_return(resource)
            expect(builder.build_xml).to be_xml(dc4_xml)
          end
        end

        describe :validate do
          attr_reader :logger

          before(:each) do
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
            builder.validate(dc4_xml)
          end

          it 'raises for invalid XML' do
            xml = File.read('spec/data/bad-mrt-datacite.xml')
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
