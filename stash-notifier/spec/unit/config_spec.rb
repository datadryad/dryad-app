Dir[File.join(__dir__, '..', '..', 'app', '*.rb')].each { |file| require file }
require 'byebug'
require 'ostruct'

class ConfigSpec
  describe 'config' do

    before(:each) do
      Config.initialize(environment: 'test')
    end

    # :logger, :environment, :update_base_url, :oai_base_url, :sets
    describe 'sets correct values' do
      it 'sets logger' do
        expect(Config.logger).to be_a(Logger)
      end

      it 'sets environment' do
        expect(Config.environment).to eql('test')
      end

      it 'sets update_base_url' do
        expect(Config.update_base_url).to eql('http://localhost:3000/stash/dataset')
      end

      it 'sets oai_base_url' do
        expect(Config.oai_base_url).to be_eql('http://uc3-mrtoai-stg.cdlib.org:37001/mrtoai/oai/v2')
      end

      it 'sets sets' do
        expect(Config.sets).to eql(['test1'])
      end
    end
  end
end
