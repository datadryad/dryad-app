module Stash
  module Repo
    describe ValidatingXMLBuilder do
      attr_reader :builder
      attr_reader :logger

      before(:each) do
        @builder = ValidatingXMLBuilder.new
        @logger = instance_double(Logger)
        allow(Rails).to receive(:logger).and_return(logger)
      end

      after(:each) do
        allow(Rails).to receive(:logger).and_call_original
      end

      describe :do_validate? do
        it 'is true in test' do
          expect(ENV.fetch('RAILS_ENV', nil)).to eq('test') # just to be sure
          expect(builder.do_validate?).to eq(true)
        end
        it 'is true in dev' do
          rails_env = ENV.fetch('RAILS_ENV', nil)
          begin
            ENV['RAILS_ENV'] = 'development'
            expect(builder.do_validate?).to eq(true)
          ensure
            ENV['RAILS_ENV'] = rails_env
          end
        end
        it 'is false in stage' do
          rails_env = ENV.fetch('RAILS_ENV', nil)
          begin
            ENV['RAILS_ENV'] = 'stage'
            expect(builder.do_validate?).to eq(false)
          ensure
            ENV['RAILS_ENV'] = rails_env
          end
        end
        it 'is false in production' do
          rails_env = ENV.fetch('RAILS_ENV', nil)
          begin
            ENV['RAILS_ENV'] = 'production'
            expect(builder.do_validate?).to eq(false)
          ensure
            ENV['RAILS_ENV'] = rails_env
          end
        end
      end

      describe :mime_type do
        it 'returns text/xml' do
          expect(builder.mime_type.to_s).to eq('text/xml')
        end
      end

      describe :build_xml do
        it 'is abstract' do
          expect { builder.build_xml }.to raise_error(NoMethodError)
        end
      end

      describe :schema do
        it 'is abstract' do
          expect { builder.schema }.to raise_error(NoMethodError)
        end
      end

      describe 'validation' do
        attr_reader :xml
        before(:each) do
          @xml = File.read('spec/data/archive/stash-wrapper.xml')

          def builder.schema
            @schema ||= Nokogiri::XML::Schema(File.open('spec/data/stash_wrapper.xsd'))
          end
        end

        describe :contents do
          it 'returns the XML, if valid' do
            good_xml = xml
            builder.define_singleton_method(:build_xml) do
              good_xml
            end
            expect(builder.contents).to eq(good_xml)
          end

          it 'raises an error, if invalid' do
            bad_xml = xml.gsub('stash', 'mash')
            builder.define_singleton_method(:build_xml) do
              bad_xml
            end
            expect(logger).to receive(:error)
            expect { builder.contents }.to raise_error(Nokogiri::XML::SyntaxError)
          end
        end

        describe :validate do
          it 'validates good XML' do
            expect(builder.validate(xml)).to eq(xml)
          end

          it 'validates bad XML' do
            bad_xml = xml.gsub('stash', 'mash')
            expect(logger).to receive(:error)
            expect { builder.validate(bad_xml) }.to raise_error(Nokogiri::XML::SyntaxError)
          end
        end
      end
    end
  end
end
