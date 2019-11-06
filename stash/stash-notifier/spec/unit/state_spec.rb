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
        FileUtils.cp(File.join(__dir__, '..', 'data', 'statefile-example.json'), my_file)
        State.ensure_statefile
        expect(File.size(my_file)).to eql(103)
      end

      it "creates a statefile if it doesn't exist" do
        my_file = File.join(__dir__, '..', '..', 'state', 'test.json')
        File.delete(my_file) if File.exist?(my_file)
        State.ensure_statefile
        expect(File.size(my_file)).to be > 0
      end
    end

    describe '#statefile_path' do
      it 'has a correct statefile path' do
        expect(State.statefile_path.end_with?('state/test.json')).to be_truthy
      end
    end

    describe '#save_state_hash' do
      it 'saves whatever hash to pretty json' do
        State.save_state_hash(hash: { cat: 'meow', 'dog': 'ruff' })
        my_val = "{\n  \"cat\": \"meow\",\n  \"dog\": \"ruff\"\n}"
        data = File.read(State.statefile_path)
        expect(data).to eql(my_val)
      end
    end

    describe '#load_state_as_hash' do
      it 'loads the state file as a hash' do
        my_val = "{\n  \"cat1\": \"meow2\",\n  \"dog3\": \"ruff4\"\n}"
        File.delete(State.statefile_path) if File.exist?(State.statefile_path)
        File.write(State.statefile_path, my_val)
        expect(State.load_state_as_hash).to eql('cat1' => 'meow2', 'dog3' => 'ruff4')
      end
    end

    describe '#sets' do
      it 'loads the set objects from the state' do
        File.delete(State.statefile_path) if File.exist?(State.statefile_path)
        State.ensure_statefile
        my_sets = State.sets
        expect(my_sets).to be_an(Array)
        expect(my_sets.first).to be_a(CollectionSet)
      end
    end

    describe '#sets_serialized_to_hash' do
      it 'serializes the set objects to a hash' do
        File.delete(State.statefile_path) if File.exist?(State.statefile_path)
        State.ensure_statefile
        expect(State.sets_serialized_to_hash).to eql('noogie' => { last_retrieved: '1970-01-01T00:00:00Z', retry_status_update: [] })
      end
    end

    describe '#save_sets_state' do
      it 'saves the state and loaded state is as expected' do
        File.delete(State.statefile_path) if File.exist?(State.statefile_path)
        State.ensure_statefile
        State.save_sets_state
        out_from_load = State.load_state_as_hash
        expect(out_from_load).to eql('noogie' => { 'last_retrieved' => '1970-01-01T00:00:00Z', 'retry_status_update' => [] })
      end
    end

    describe '#create_pid' do
      it 'saves a pid file' do
        Config.initialize(environment: 'test')
        pid_file = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'state', "#{Config.environment}.pid"))
        File.delete(pid_file) if File.exist?(pid_file)
        State.create_pid
        expect(File.exist?(pid_file)).to be_truthy
      end
    end

    describe '#remove_pid' do
      it 'removes the pid file' do
        Config.initialize(environment: 'test')
        pid_file = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'state', "#{Config.environment}.pid"))
        File.delete(pid_file) if File.exist?(pid_file)
        State.create_pid
        State.remove_pid
        expect(File.exist?(pid_file)).to be_falsey
      end
    end
  end
end
