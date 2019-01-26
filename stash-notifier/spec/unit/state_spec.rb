Dir[File.join(__dir__, '..', '..', 'app', '*.rb')].each { |file| require file }
require 'byebug'
require 'ostruct'
require 'fileutils'

class StateSpec
  describe 'state' do

    before(:each) do
      Config.initialize(environment: 'test')

      logger = double('logger')
      allow(logger).to receive(:info)
      allow(logger).to receive(:error)
      allow(Config).to receive(:logger).and_return(logger)

      allow(Config).to receive(:sets).and_return(['noogie'])
    end

    describe '#ensure_statefile' do
      it 'leaves statefile alone if exists' do

        my_file = File.join(__dir__, '..', '..', 'state', 'test.json')
        File.delete(my_file) if File.exist?(my_file)
        FileUtils.touch(my_file)
        expect(File.size(my_file)).to eql(0)
      end
    end
  end
end
