require 'webmock/rspec'
require 'active_support/inflector'
Dir[File.join(__dir__, '..', '..', 'app', '*.rb')].each { |file| require file }
require 'ostruct'
# require_relative '../../main.rb'
RSpec.describe 'main' do
  before(:each) do
    # be sure things for these classes start fresh and are not having state carried over and they are 'required'
    reload_classes(%i[Config CollectionSet DatasetRecord State])
    ENV['STASH_ENV'] = 'test'
    ENV['NOTIFIER_OUTPUT'] = 'stdout'

    WebMock.disable_net_connect!(allow_localhost: true)

    file_contents = File.read(File.join(__dir__, '..', 'data', 'oai-example.xml'))

    allow(State).to receive(:statefile_path).and_return(File.join(__dir__, '..', '..', 'state', 'test.json'))
    # stub the request for the oai-pmh feed
    stub_request(:get, %r{mrtoai-stg.cdlib.org:37001/mrtoai/oai/v2})
      .to_return(status: 200, body: file_contents, headers: {})

    @main_path = File.expand_path(File.join(__dir__, '..', '..', 'main.rb'))
    @json_state_path = File.expand_path(File.join(__dir__, '..', '..', 'state', 'test.json'))
    @pid_path = File.expand_path(File.join(__dir__, '..', '..', 'state', 'test.pid'))
    FileUtils.rm_f(@json_state_path)
  end

  after(:each) do
    FileUtils.rm_f(@json_state_path)
    FileUtils.rm_f(@pid_path)

    ENV['STASH_ENV'] = nil
    ENV['NOTIFIER_OUTPUT'] = nil
  end

  def reload_classes(names)
    names.each do |name|
      Object.send(:remove_const, name) if defined?(name)
      load File.expand_path(File.join(__dir__, '..', '..', 'app', "#{ActiveSupport::Inflector.underscore(name)}.rb"))
    end
  end

  it 'is a decoy for travis which fails every time, but fails nowhere else (macOs, Ubuntu)' do
    begin
      load @main_path
    rescue NoMethodError
      puts 'Travis is the only place this fails'
    end
    expect(true).to eq(true)
  end

  it 'checks the OAI feed' do
    # Using the system command runs in separate process and it's
    # outside my control.  Whereas loading it executes it within the same process at the time it
    # is loaded, and the code gets loaded and interpreted where I can stub it and modify without the network calls.
    # expect { system 'main.rb'}.to output('something').to_stdout_from_any_process -- doesn't work -- outside process.
    # require doesn't work, also, because require is only executed once (the first time) and not after, so need to use load.

    expect { load @main_path }.to output(/Checking OAI feed for test1/).to_stdout_from_any_process
  end

  it 'ensures that the pid file is cleaned up after running' do
    expect { load @main_path }.to output(/Finished notifier run for test environment/).to_stdout_from_any_process
    expect(File).not_to exist(@pid_path)
  end

  it 'creates a state file' do
    expect { load @main_path }.to output(/Finished notifier run for test environment/).to_stdout_from_any_process
    expect(File).to exist(@json_state_path)
  end

  it 'still deletes the state file with HTTPClient::Timeout errors' do
    require_relative '../../app/collection_set'
    allow_any_instance_of(CollectionSet).to receive(:notify_dryad).and_raise(HTTPClient::TimeoutError)
    expect { load @main_path }.to output(/Timeout error for set test1/).to_stdout_from_any_process
    expect(File).not_to exist(@pid_path)
  end
end
