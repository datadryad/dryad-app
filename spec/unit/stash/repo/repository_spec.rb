require 'spec_helper'
require 'fileutils'
require 'tmpdir'

module Stash
  module Repo
    describe Repository do
      attr_reader :repo
      attr_reader :logger

      before(:each) do
        url_helpers = double(Module) # yes, apparently URL helpers are an anonymous module
        @repo = Repository.new(url_helpers: url_helpers)

        @logger = instance_double(Logger)
        allow(Rails).to receive(:logger).and_return(logger)
        allow(logger).to receive(:info)

        immediate_executor = Concurrent::ImmediateExecutor.new
        allow(Concurrent).to receive(:global_io_executor).and_return(immediate_executor)

        pool = double(ActiveRecord::ConnectionAdapters::ConnectionPool)
        allow(ActiveRecord::Base).to receive(:connection_pool).and_return(pool)
        allow(pool).to receive(:with_connection).and_yield

        allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_now)
      end

      after(:each) do
        allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_now).and_call_original
        allow(Concurrent).to receive(:global_io_executor).and_call_original
        allow(Rails).to receive(:logger).and_call_original
      end

      describe :create_submission_job do
        it 'is abstract' do
          expect { repo.create_submission_job(resource_id: 17) }.to raise_error(NoMethodError)
        end
      end

      describe :submit do
        attr_reader :resource_id
        attr_reader :resource
        attr_reader :res_upload_dir
        attr_reader :uploads
        attr_reader :job

        before(:each) do
          @resource_id = 53
          @resource = double(StashEngine::Resource)
          allow(resource).to receive(:id).and_return(resource_id)
          allow(resource).to receive(:current_state=)
          allow(StashEngine::Resource).to receive(:find).with(resource_id).and_return(resource)

          @res_upload_dir = Dir.mktmpdir
          allow(StashEngine::Resource).to receive(:upload_dir_for).with(resource_id).and_return(res_upload_dir)

          @uploads = Array.new(3) do |index|
            upload = double(StashEngine::FileUpload)
            temp_file_path = File.join(res_upload_dir, "file-#{index}.bin")
            FileUtils.touch(temp_file_path)
            allow(upload).to receive(:temp_file_path).and_return(temp_file_path)
            upload
          end
          allow(resource).to receive(:file_uploads).and_return(uploads)

          @request_host = 'stash.example.org'
          @request_port = 80

          @job = SubmissionJob.new(resource_id: resource_id)
          expected_id = resource_id
          returned_job = job
          repo.define_singleton_method(:create_submission_job) do |params|
            raise ArgumentError unless params[:resource_id] == expected_id
            returned_job
          end

          allow(StashEngine::SubmissionLog).to receive(:create)
        end

        after(:each) do
          FileUtils.remove_entry_secure(res_upload_dir) if File.directory?(res_upload_dir)
        end

        def submit_resource
          repo.submit(resource_id: resource_id)
        end

        describe :handle_success do
          before(:each) do
            allow(job).to receive(:submit!).and_return(SubmissionResult.new(resource_id: resource_id, request_desc: 'test', message: 'whee!'))
            allow(job).to receive(:description).and_return('test')
          end

          it 'sends a "submission succeeded" email' do
            message = instance_double(ActionMailer::MessageDelivery)
            expect(StashEngine::UserMailer).to receive(:submission_succeeded).with(resource).and_return(message)
            expect(message).to receive(:deliver_now)
            submit_resource
          end

          it 'removes uploaded files on success' do
            expect(logger).not_to receive(:warn)
            expect(logger).not_to receive(:error)
            submit_resource
            uploads.each do |upload|
              expect(File.exist?(upload.temp_file_path)).to be_falsey
            end
          end

          it 'removes the uploads dir on success' do
            expect(logger).not_to receive(:warn)
            expect(logger).not_to receive(:error)
            submit_resource
            expect(File.exist?(res_upload_dir)).to be_falsey
          end

          it 'sets the state to submitted' do
            expect(resource).to receive(:current_state=).with('processing')
            expect(resource).to receive(:current_state=).with('published')
            submit_resource
          end

          it 'updates the submission log table' do
            expect(StashEngine::SubmissionLog).to receive(:create).with(
              resource_id: resource_id,
              archive_submission_request: 'test',
              archive_response: 'whee!'
            )
            submit_resource
          end

          describe 'unexpected errors' do
            before(:each) do
              allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_now).and_raise(Net::SMTPAuthenticationError)
            end
            it 'logs the error' do
              msg = nil
              expect(logger).to(receive(:error)).once { |m| msg = m }
              submit_resource
              expect(msg).to include(resource_id.to_s)
              expect(msg).to include(Net::SMTPAuthenticationError.to_s)
            end

            it 'leaves uploaded files in place on failure' do
              submit_resource
              uploads.each do |upload|
                expect(File.exist?(upload.temp_file_path)).to be_truthy
              end
            end

            it 'leaves the uploads dir in place on failure' do
              submit_resource
              expect(File.exist?(res_upload_dir)).to be_truthy
            end

            it 'sets the state to submitted' do
              expect(resource).to receive(:current_state=).with('processing')
              expect(resource).to receive(:current_state=).with('published')
              submit_resource
            end

            it 'updates the submission log table' do
              expect(StashEngine::SubmissionLog).to receive(:create).with(
                resource_id: resource_id,
                archive_submission_request: 'test',
                archive_response: 'whee!'
              )
              submit_resource
            end
          end

          describe 'file cleanup errors' do
            before(:each) do
              allow(FileUtils).to receive(:remove_entry_secure).and_raise(Errno::ENOENT)
            end
            after(:each) do
              allow(FileUtils).to receive(:remove_entry_secure).and_call_original
            end
            it 'logs the error' do
              msg = nil
              expect(logger).to(receive(:warn)).once { |m| msg = m }
              submit_resource
              expect(msg).to include(resource_id.to_s)
              expect(msg).to include('No such file or directory')
            end

            it 'sets the state to submitted' do
              expect(resource).to receive(:current_state=).with('processing')
              expect(resource).to receive(:current_state=).with('published')
              submit_resource
            end

            it 'updates the submission log table' do
              expect(StashEngine::SubmissionLog).to receive(:create).with(
                resource_id: resource_id,
                archive_submission_request: 'test',
                archive_response: 'whee!'
              )
              submit_resource
            end
          end
        end

        describe :handle_failure do
          before(:each) do
            allow(job).to receive(:submit!).and_raise(ActiveRecord::ConnectionTimeoutError)
            allow(job).to receive(:description).and_return('test')
            allow(logger).to receive(:error) { |m| $stderr.puts(m) }
          end
          it 'sends a "submission failed" email' do
            message = instance_double(ActionMailer::MessageDelivery)
            expect(StashEngine::UserMailer).to receive(:submission_failed).with(resource, kind_of(ActiveRecord::ConnectionTimeoutError)).and_return(message)
            expect(message).to receive(:deliver_now)
            submit_resource
          end

          it 'sends an error report email' do
            message = instance_double(ActionMailer::MessageDelivery)
            expect(StashEngine::UserMailer).to receive(:error_report).with(resource, kind_of(ActiveRecord::ConnectionTimeoutError)).and_return(message)
            expect(message).to receive(:deliver_now)
            submit_resource
          end

          it 'logs the error' do
            msg = nil
            expect(logger).to(receive(:error)).once { |m| msg = m }
            submit_resource
            expect(msg).to include(resource_id.to_s)
            expect(msg).to include(ActiveRecord::ConnectionTimeoutError.to_s)
          end

          it 'leaves uploaded files in place on failure' do
            submit_resource
            uploads.each do |upload|
              expect(File.exist?(upload.temp_file_path)).to be_truthy
            end
          end

          it 'leaves the uploads dir in place on success' do
            submit_resource
            expect(File.exist?(res_upload_dir)).to be_truthy
          end

          it 'sets the state to failed' do
            expect(resource).to receive(:current_state=).with('processing')
            expect(resource).to receive(:current_state=).with('error')
            submit_resource
          end

          it 'updates the submission log table' do
            expect(StashEngine::SubmissionLog).to receive(:create).with(
              resource_id: resource_id,
              archive_submission_request: 'test',
              archive_response: ActiveRecord::ConnectionTimeoutError.to_s
            )
            submit_resource
          end

          describe 'unexpected errors' do
            before(:each) do
              allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_now).and_raise(Net::SMTPAuthenticationError)
            end
            it 'logs the error' do
              msg = nil
              expect(logger).to(receive(:error)).twice { |m| msg = m }
              submit_resource
              expect(msg).to include(resource_id.to_s)
              expect(msg).to include(Net::SMTPAuthenticationError.to_s)
            end

            it 'leaves uploaded files in place on failure' do
              submit_resource
              uploads.each do |upload|
                expect(File.exist?(upload.temp_file_path)).to be_truthy
              end
            end

            it 'leaves the uploads dir in place on success' do
              submit_resource
              expect(File.exist?(res_upload_dir)).to be_truthy
            end

            it 'sets the state to failed' do
              expect(resource).to receive(:current_state=).with('processing')
              expect(resource).to receive(:current_state=).with('error')
              submit_resource
            end

            it 'updates the submission log table' do
              expect(StashEngine::SubmissionLog).to receive(:create).with(
                resource_id: resource_id,
                archive_submission_request: 'test',
                archive_response: ActiveRecord::ConnectionTimeoutError.to_s
              )
              submit_resource
            end
          end
        end
      end
    end
  end
end
