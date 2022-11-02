Dir[File.join(__dir__, '..', '..', 'app', '*.rb')].sort.each { |file| require file }
# force reload of State because of changes
require 'ostruct'
require 'fileutils'

class StateSpec
  describe 'state' do

    before(:each) do
      allow(State).to receive(:statefile_path).and_return(File.join(__dir__, '..', '..', 'state', 'test.json'))

      Config.initializer(environment: 'test')

      logger = double('logger')
      allow(logger).to receive(:info)
      allow(logger).to receive(:error)
      allow(Config).to receive(:logger).and_return(logger)

      allow(Config).to receive(:sets).and_return(['test1'])
    end

    describe '#ensure_statefile' do
      it 'leaves original statefile entries intact and just adds' do
        original_file = File.expand_path(File.join(__dir__, '..', 'data', 'statefile-example.json'))
        my_file = File.expand_path(File.join(__dir__, '..', '..', 'state', 'test.json'))
        FileUtils.rm_f(my_file)
        FileUtils.cp(original_file, my_file)
        State.ensure_statefile
        my_file_json = JSON.parse(File.read(my_file))
        original_file_json = JSON.parse(File.read(original_file))
        expect(my_file_json.keys).to include(original_file_json.keys.first)
        expect(my_file_json['noogie']).to eq(original_file_json['noogie'])
      end

      it "creates a statefile if it doesn't exist" do
        my_file = File.join(__dir__, '..', '..', 'state', 'test.json')
        FileUtils.rm_f(my_file)
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
        State.save_state_hash(hash: { cat: 'meow', dog: 'ruff' })
        my_val = "{\n  \"cat\": \"meow\",\n  \"dog\": \"ruff\"\n}"
        data = File.read(State.statefile_path)
        expect(data).to eql(my_val)
      end
    end

    describe '#load_state_as_hash' do
      it 'loads the state file as a hash' do
        my_val = "{\n  \"cat1\": \"meow2\",\n  \"dog3\": \"ruff4\"\n}"
        FileUtils.rm_f(State.statefile_path)
        File.write(State.statefile_path, my_val)
        expect(State.load_state_as_hash).to eql('cat1' => 'meow2', 'dog3' => 'ruff4')
      end
    end

    describe '#sets' do
      it 'loads the set objects from the state' do
        FileUtils.rm_f(State.statefile_path)
        State.ensure_statefile
        my_sets = State.sets
        expect(my_sets).to be_an(Array)
        expect(my_sets.first).to be_a(CollectionSet)
      end
    end

    describe '#sets_serialized_to_hash' do
      it 'serializes the set objects to a hash' do
        FileUtils.rm_f(State.statefile_path)
        State.ensure_statefile
        expect(State.sets_serialized_to_hash).to eql('test1' => { last_retrieved: '1970-01-01T00:00:00Z', retry_status_update: [] })
      end
    end

    describe '#save_sets_state' do
      it 'saves the state and loaded state is as expected' do
        FileUtils.rm_f(State.statefile_path)
        State.ensure_statefile
        State.save_sets_state
        out_from_load = State.load_state_as_hash
        expect(out_from_load).to eql('test1' => { 'last_retrieved' => '1970-01-01T00:00:00Z', 'retry_status_update' => [] })
      end
    end

    describe '#create_pid' do
      it 'saves a pid file' do
        Config.initializer(environment: 'test')
        pid_file = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'state', "#{Config.environment}.pid"))
        FileUtils.rm_f(pid_file)
        State.create_pid
        expect(File.exist?(pid_file)).to be_truthy
        State.remove_pid
        expect(File.exist?(pid_file)).to be_falsey
      end
    end

    describe '#remove_pid' do
      it 'removes the pid file' do
        Config.initializer(environment: 'test')
        pid_file = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'state', "#{Config.environment}.pid"))
        FileUtils.rm_f(pid_file)
        State.create_pid
        State.remove_pid
        expect(File.exist?(pid_file)).to be_falsey
      end
    end
  end
end
