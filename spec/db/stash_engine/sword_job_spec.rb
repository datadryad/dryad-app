require 'db_spec_helper'

require 'fileutils'
require 'webmock'

module StashEngine
  describe SwordJob do

    attr_reader :title
    attr_reader :doi
    attr_reader :zipfile
    attr_reader :resource_id
    attr_reader :sword_params
    attr_reader :request_host
    attr_reader :request_port
    attr_reader :tmpdir
    attr_reader :logger

    before(:all) do
      WebMock.disable_net_connect!

      @title = 'A Zebrafish Model for Studies on Esophageal Epithelial Biology'
      @doi = 'doi:10.15146/R3RG6G'
      @request_host = 'example.org'
      @request_port = 80

      @sword_params = {
          collection_uri: 'http://example.org/sword/my_collection',
          username: 'elvis',
          password: 'presley'
      }.freeze

    end

    before(:each) do
      @tmpdir = Dir.mktmpdir
      FileUtils.cp('spec/data/archive.zip', tmpdir)
      @zipfile = "#{tmpdir}/archive.zip"

      resource = Resource.create
      @resource_id = resource.id

      @logger = instance_double(Logger)
      allow(logger).to receive(:debug)
      allow(logger).to receive(:info)
      allow(logger).to receive(:warn)
      allow(logger).to receive(:error)

      @rails_logger = Rails.logger
      Rails.logger = logger

      @immediate_executor = Concurrent::ImmediateExecutor.new
      allow(Concurrent).to receive(:global_io_executor).and_return(@immediate_executor)

      allow(RestClient::Request).to receive(:execute)
    end

    after(:each) do
      allow(Concurrent).to receive(:global_io_executor).and_call_original
      Rails.logger = @rails_logger
      FileUtils.remove_entry_secure tmpdir
    end

    describe '#submit_async' do
      it 'submits' do
        future = SwordJob.submit_async(
            title: title,
            doi: doi,
            zipfile: zipfile,
            resource_id: resource_id,
            sword_params: sword_params,
            request_host: request_host,
            request_port: request_port
        )
        future.no_error!(5)
        expect(future.fulfilled?).to be_true
      end
    end

  end
end
