require 'db_spec_helper'

require 'fileutils'
require 'webmock'

module StashEngine
  module Sword
    describe SubmitJob do
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
      attr_reader :resource_upload_dir
      attr_reader :some_upload
      attr_reader :some_tempfile

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

      def update_uri
        "http://example.org/#{doi}/edit"
      end

      def download_uri
        "http://example.org/#{doi}/em"
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
        allow(receipt).to(receive(:em_iri)).and_return(download_uri)
        allow(receipt).to(receive(:edit_iri)).and_return(update_uri)

        @sword_client = instance_double(Stash::Sword::Client)
        allow(@sword_client).to receive(:update).and_return(200)
        allow(@sword_client).to receive(:create) { receipt }
        allow(Stash::Sword::Client).to receive(:new) { @sword_client }

        allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_now)
      end

      after(:each) do
        allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_now).and_call_original
        allow(Concurrent).to receive(:global_io_executor).and_call_original
        Rails.logger = @rails_logger
        FileUtils.remove_entry_secure tmpdir
      end

      def create_some_tempfile
        @some_tempfile = File.join(uploads_dir, "#{resource_id}_foo.bin")
        File.write(some_tempfile, '')
      end

      def create_some_upload
        @some_upload = Tempfile.new(%w(foo bin)).path
        File.write(some_upload, '')
        FileUpload.create(
          resource_id: resource_id,
          upload_file_name: 'foo.bin',
          upload_content_type: 'application/binary',
          upload_file_size: 0,
          file_state: 'created',
          temp_file_path: some_upload
        )
      end

      def create_resource_upload_dir
        @resource_upload_dir = File.join(uploads_dir, resource_id.to_s)
        FileUtils.mkdir_p(resource_upload_dir)
      end

      def create_cleanup_files
        create_resource_upload_dir
        create_some_upload
        create_some_tempfile
      end

      def submit_resource
        package = Package.new(
          title: title,
          doi: doi,
          zipfile: zipfile,
          resource_id: resource_id,
          sword_params: sword_params,
          request_host: request_host,
          request_port: request_port
        )
        SubmitJob.submit_async(package).value!
      end

      describe '#submit_async' do
        describe '#create' do
          describe 'success handling' do
            it 'creates a SWORD resource' do
              expect(sword_client).to receive(:create).with(doi: doi, zipfile: zipfile)
              submit_resource
            end

            it 'sets the update and download URIs' do
              resource = submit_resource
              expect(resource.download_uri).to eq(download_uri)
              expect(resource.update_uri).to eq(update_uri)
            end

            it 'sends a "create succeeded" email' do
              message = instance_double(ActionMailer::MessageDelivery)
              expect(UserMailer).to receive(:create_succeeded).with(kind_of(Resource), title, request_host, request_port).and_return(message)
              expect(message).to receive(:deliver_now)
              submit_resource
            end

            it 'cleans up on success' do
              create_cleanup_files
              submit_resource
              [resource_upload_dir, some_upload, some_tempfile].each { |f| expect(File.exist?(f)).to be_falsey }
            end
          end

          describe 'failure handling' do
            before(:each) do
              expect(sword_client).to receive(:create).and_raise(RestClient::NotFound)
            end

            it 'logs an error' do
              expect(logger).to receive(:error).with(/.*Not Found.*/)
              expect { submit_resource }.to raise_error(RestClient::NotFound)
            end

            it 'logs a detailed warning' do
              expect(logger).to receive(:warn).with(/SubmitJob for '#{Regexp.quote(title)}' \(#{Regexp.quote(doi)}\) failed at [0-9 \-+:]+: Not Found/)
              expect { submit_resource }.to raise_error(RestClient::NotFound)
            end

            it 'sets the current resource state' do
              expect { submit_resource }.to raise_error(RestClient::NotFound)
              resource = Resource.find(resource_id)
              current_state = resource.current_state
              expect(current_state.resource_state).to eq('error')
            end

            it 'leaves temp files in place' do
              create_cleanup_files
              expect { submit_resource }.to raise_error(RestClient::NotFound)
              [resource_upload_dir, some_upload, some_tempfile].each { |f| expect(File.exist?(f)).to be_truthy }
            end
          end
        end

        describe '#update' do
          before(:each) do
            resource = Resource.find(resource_id)
            resource.update_uri = update_uri
            resource.download_uri = download_uri
            resource.save
          end

          it 'updates a SWORD resource' do
            expect(sword_client).to receive(:update).with(edit_iri: update_uri, zipfile: zipfile).and_return(200)
            submit_resource
          end

          it 'sends an "update succeeded" email' do
            message = instance_double(ActionMailer::MessageDelivery)
            expect(UserMailer).to receive(:update_succeeded).with(kind_of(Resource), title, request_host, request_port).and_return(message)
            expect(message).to receive(:deliver_now)
            submit_resource
          end

          it 'cleans up on success' do
            create_cleanup_files
            submit_resource
            [resource_upload_dir, some_upload, some_tempfile].each { |f| expect(File.exist?(f)).to be_falsey }
          end

          describe 'failure handling' do
            before(:each) do
              expect(sword_client).to receive(:update).and_raise(RestClient::NotFound)
            end

            it 'logs an error' do
              expect(logger).to receive(:error).with(/.*Not Found.*/)
              expect { submit_resource }.to raise_error(RestClient::NotFound)
            end

            it 'logs a detailed warning' do
              expect(logger).to receive(:warn).with(/SubmitJob for '#{Regexp.quote(title)}' \(#{Regexp.quote(doi)}\) failed at [0-9 \-+:]+: Not Found/)
              expect { submit_resource }.to raise_error(RestClient::NotFound)
            end

            it 'sets the current resource state' do
              expect { submit_resource }.to raise_error(RestClient::NotFound)
              resource = Resource.find(resource_id)
              current_state = resource.current_state
              expect(current_state.resource_state).to eq('error')
            end

            it 'leaves temp files in place' do
              create_cleanup_files
              expect { submit_resource }.to raise_error(RestClient::NotFound)
              [resource_upload_dir, some_upload, some_tempfile].each { |f| expect(File.exist?(f)).to be_truthy }
            end
          end
        end
      end
    end
  end
end
