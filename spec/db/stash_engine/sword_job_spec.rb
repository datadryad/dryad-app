require 'db_spec_helper'

require 'fileutils'
require 'webmock'

module StashEngine
  describe SwordJob do
    attr_reader :title
    attr_reader :doi
    attr_reader :resource_id
    attr_reader :zipfile
    attr_reader :uploads_dir
    attr_reader :sword_params
    attr_reader :sword_client
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
      @uploads_dir = File.join(@tmpdir, 'uploads')
      FileUtils.mkdir_p(uploads_dir)
      allow(Resource).to receive(:uploads_dir).and_return(uploads_dir)

      resource = Resource.create
      @resource_id = resource.id

      FileUtils.cp('spec/data/archive.zip', uploads_dir)
      @zipfile = File.join(uploads_dir, 'archive.zip')

      @logger = instance_double(Logger)
      allow(logger).to receive(:debug)
      allow(logger).to receive(:info)
      allow(logger).to receive(:warn)
      allow(logger).to receive(:error)

      @rails_logger = Rails.logger
      Rails.logger = logger

      @immediate_executor = Concurrent::ImmediateExecutor.new
      allow(Concurrent).to receive(:global_io_executor).and_return(@immediate_executor)

      receipt = instance_double(Stash::Sword::DepositReceipt)
      allow(receipt).to(receive(:em_iri)).and_return("http://example.org/#{doi}/em")
      allow(receipt).to(receive(:edit_iri)).and_return("http://example.org/#{doi}/edit")

      @sword_client = instance_double(Stash::Sword::Client)
      allow(@sword_client).to receive(:update).and_return(200)
      allow(@sword_client).to receive(:create) { receipt }
      allow(Stash::Sword::Client).to receive(:new) { @sword_client }

      allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_now)
    end

    after(:each) do
      allow(Concurrent).to receive(:global_io_executor).and_call_original
      Rails.logger = @rails_logger
      FileUtils.remove_entry_secure tmpdir
    end

    def submit_resource
      SwordJob.submit_async(
        title: title,
        doi: doi,
        zipfile: zipfile,
        resource_id: resource_id,
        sword_params: sword_params,
        request_host: request_host,
        request_port: request_port
      ).value!
    end

    describe '#submit_async' do
      describe '#create' do
        it 'creates a SWORD resource' do
          expect(sword_client).to receive(:create).with(doi: doi, zipfile: zipfile)
          submit_resource
        end

        it 'sets the update and download URIs' do
          resource = submit_resource
          expect(resource.download_uri).to eq("http://example.org/#{doi}/em")
          expect(resource.update_uri).to eq("http://example.org/#{doi}/edit")
        end

        it 'sends an "update succeeded" email' do
          message = instance_double(ActionMailer::MessageDelivery)
          expect(UserMailer).to receive(:create_succeeded).with(kind_of(Resource), title, request_host, request_port).and_return(message)
          expect(message).to receive(:deliver_now)
          submit_resource
        end
      end
    end
  end
end
