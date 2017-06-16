require 'spec_helper'

module Stash
  module Repo
    describe ValidatingXMLBuilder do
      attr_reader :builder

      before(:each) do
        @builder = ValidatingXMLBuilder.new
      end

      describe :do_validate? do
        it 'is true in test' do
          expect(ENV['RAILS_ENV']).to eq('test') # just to be sure
          expect(builder.do_validate?).to eq(true)
        end
        it 'is true in dev' do
          rails_env = ENV['RAILS_ENV']
          begin
            ENV['RAILS_ENV'] = 'development'
            expect(builder.do_validate?).to eq(true)
          ensure
            ENV['RAILS_ENV'] = rails_env
          end
        end
        it 'is false in stage' do
          rails_env = ENV['RAILS_ENV']
          begin
            ENV['RAILS_ENV'] = 'stage'
            expect(builder.do_validate?).to eq(false)
          ensure
            ENV['RAILS_ENV'] = rails_env
          end
        end
        it 'is false in production' do
          rails_env = ENV['RAILS_ENV']
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

      describe :validate do
        it 'validates XML'
      end

    end
  end
end
