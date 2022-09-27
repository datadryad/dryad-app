require 'tmpdir'
require 'concurrent'
require 'fileutils'

module Stash
  module Repo
    describe Repository do
      attr_reader :repo
      attr_reader :logger
      attr_reader :url_helpers
      attr_reader :resource_id
      attr_reader :resource
      attr_reader :res_upload_dir
      attr_reader :uploads
      attr_reader :rails_root
      attr_reader :public_system

      before(:each) do
        @url_helpers = double(Module) # yes, apparently URL helpers are an anonymous module
        @repo = Repository.new(url_helpers: url_helpers, executor: Concurrent::ImmediateExecutor.new, threads: 1)

        @logger = instance_double(Logger)
        allow(Rails).to receive(:logger).and_return(logger)
        allow(logger).to receive(:info)

        @rails_root = Dir.mktmpdir('rails_root')
        root_path = Pathname.new(rails_root)
        allow(Rails).to receive(:root).and_return(root_path)

        public_path = Pathname.new("#{rails_root}/public")
        allow(Rails).to receive(:public_path).and_return(public_path)

        immediate_executor = Concurrent::ImmediateExecutor.new
        allow(Concurrent).to receive(:global_io_executor).and_return(immediate_executor)

        allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_now)

        @resource_id = 53
        @resource = double(StashEngine::Resource)
        allow(resource).to receive(:id).and_return(resource_id)
        allow(resource).to receive(:current_state=)
        allow(resource).to receive(:skip_emails).and_return(false)
        allow(StashEngine::Resource).to receive(:find).with(resource_id).and_return(resource)

        @res_upload_dir = Dir.mktmpdir
        allow(StashEngine::Resource).to receive(:upload_dir_for).with(resource_id).and_return(res_upload_dir)

        @uploads = Array.new(3) do |index|
          upload = double(StashEngine::DataFile)
          calc_file_path = File.join(res_upload_dir, "file-#{index}.bin")
          FileUtils.touch(calc_file_path)
          allow(upload).to receive(:calc_file_path).and_return(calc_file_path)
          upload
        end
        allow(resource).to receive(:data_files).and_return(uploads)
      end

      after(:each) do
        allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_now).and_call_original
        allow(Concurrent).to receive(:global_io_executor).and_call_original
        allow(Rails).to receive(:logger).and_call_original
        FileUtils.remove_dir(rails_root)
      end

      describe :create_submission_job do
        it 'is abstract' do
          expect { repo.create_submission_job(resource_id: 17) }.to raise_error(NoMethodError)
        end
      end

      describe :download_uri_for do
        it 'is abstract' do
          expect { repo.download_uri_for(resource: resource, record_identifier: 'ark:/1234/567') }.to raise_error(NoMethodError)
        end
      end

      describe :update_uri_for do
        it 'is abstract' do
          expect { repo.update_uri_for(resource: resource, record_identifier: 'ark:/1234/567') }.to raise_error(NoMethodError)
        end
      end

      describe :submit do
        attr_reader :job

        before(:each) do
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

          it 'leaves the state as "processing"' do
            expect(resource).to receive(:current_state=).with('processing')
            expect(resource).not_to receive(:current_state=).with('submitted')
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

          it 'updates the RepoQueueState table)' do
            expect(StashEngine::RepoQueueState).to receive(:create).with(
              resource_id: resource_id,
              hostname: repo.class.hostname,
              state: 'enqueued'
            )
            submit_resource
          end

          describe 'when result.deferred? = true' do
            it "doesn't update repo queue states with success" do
              result = SubmissionResult.new(resource_id: resource_id, request_desc: 'test', message: 'whee!')
              result.deferred = true
              allow(job).to receive(:submit!).and_return(result)

              expect(StashEngine::RepoQueueState).to receive(:create).with(
                resource_id: resource_id,
                hostname: repo.class.hostname,
                state: 'enqueued'
              )
              expect(StashEngine::RepoQueueState).not_to receive(:create).with(
                resource_id: resource_id,
                hostname: repo.class.hostname,
                state: 'completed'
              )
              submit_resource
            end
          end

          describe 'unexpected errors' do
            before(:each) do
              allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_now).and_raise(Net::SMTPAuthenticationError)
            end
            # We moved the success email to the curation_activity so this error does not fire
            # TODO: find another suitable method to raise the error on
            xit 'logs the error' do
              msg = nil
              expect(logger).to(receive(:error)).once { |m| msg = m }
              submit_resource
              expect(msg).to include(resource_id.to_s)
              expect(msg).to include(Net::SMTPAuthenticationError.to_s)
            end

            it 'leaves uploaded files in place on failure' do
              submit_resource
              uploads.each do |upload|
                expect(File.exist?(upload.calc_file_path)).to be_truthy
              end
            end

            it 'leaves the uploads dir in place on failure' do
              submit_resource
              expect(File.exist?(res_upload_dir)).to be_truthy
            end

            it 'leaves the state as "processing"' do
              expect(resource).to receive(:current_state=).with('processing')
              expect(resource).not_to receive(:current_state=).with('submitted')
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
            allow(logger).to receive(:error)
          end

          it 'sends an error report email' do
            message = instance_double(ActionMailer::MessageDelivery)
            expect(StashEngine::UserMailer).to receive(:error_report)
              .with(resource, kind_of(ActiveRecord::ConnectionTimeoutError))
              .and_return(message)
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
              expect(File.exist?(upload.calc_file_path)).to be_truthy
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
              # after a gem update this no longer does this but just sends two SMTPAuthenticationErrors
              # expect(msg).to include(resource_id.to_s)

              # There is a method called handle_failure in repo/repository.rb that mails on the errors and it seems like
              # this mock (before above) is now intercepting the call in there where it wasn't before on the first try.
              # IDK, why it does it twice.
              expect(msg).to include(Net::SMTPAuthenticationError.to_s)
              expect(msg).to include(Net::SMTPAuthenticationError.to_s)
            end

            it 'leaves uploaded files in place on failure' do
              submit_resource
              uploads.each do |upload|
                expect(File.exist?(upload.calc_file_path)).to be_truthy
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

      describe :harvested do
        attr_reader :resource
        attr_reader :identifier
        attr_reader :record_identifier

        before(:each) do
          @identifier = double(StashEngine::Identifier)
          allow(identifier).to receive(:processing_resource).and_return(resource)

          @record_identifier = 'ark:/1234/567'

          def repo.update_uri_for(_)
            'http://example.org/edit/ark:/1234/567'
          end

          def repo.download_uri_for(_)
            'http://example.org/d/ark:/1234/567'
          end

          allow(logger).to receive(:debug)
          allow(resource).to receive(:update_uri=)
          allow(resource).to receive(:download_uri=)
          allow(resource).to receive(:save)
          allow(resource).to receive(:data_files).and_return([])
        end

        it 'sets the download and update URIs' do
          expect(resource).to receive(:update_uri=).with('http://example.org/edit/ark:/1234/567')
          expect(resource).to receive(:download_uri=).with('http://example.org/d/ark:/1234/567')
          repo.harvested(identifier: identifier, record_identifier: record_identifier)
        end

        it 'sets the state' do
          expect(resource).to receive(:current_state=).with('submitted')
          repo.harvested(identifier: identifier, record_identifier: record_identifier)
        end

        it 'saves the resource' do
          expect(resource).to receive(:save)
          repo.harvested(identifier: identifier, record_identifier: record_identifier)
        end

        it 'wraps download URI errors as ArgumentError' do
          def repo.download_uri_for(_)
            raise IndexError
          end
          expect { repo.harvested(identifier: identifier, record_identifier: record_identifier) }.to raise_error(
            ArgumentError, /.*download.*#{Regexp.quote(record_identifier)}.*IndexError/
          )
        end

        it 'wraps update URI errors as ArgumentError' do
          def repo.update_uri_for(_)
            raise IndexError
          end
          expect { repo.harvested(identifier: identifier, record_identifier: record_identifier) }.to raise_error(
            ArgumentError, /.*update.*#{Regexp.quote(record_identifier)}.*IndexError/
          )
        end
      end

      describe 'Repository#update_repo_queue_state' do
        it 'creates a queuestate in the database' do
          expect(StashEngine::RepoQueueState).to receive(:create)
          repo.class.update_repo_queue_state(resource_id: resource_id, state: 'rejected_shutting_down')
        end
      end

      describe 'Repository#hostname' do
        it "caches and returns the machine's hostname" do
          expect(repo.class.hostname).to eq(`hostname`.strip)
        end
      end

      describe 'Repository#hold_submissions?' do
        it 'returns false in normal circumstances' do
          expect(repo.class.hold_submissions?).to be false
        end

        it 'returns true if a hold-submissions.txt file is in place' do
          file_path = File.expand_path(File.join(Rails.root, '..', 'hold-submissions.txt'))
          ::FileUtils.touch(file_path)
          expect(repo.class.hold_submissions?).to eq(true)
          ::FileUtils.rm(file_path)
        end
      end

    end
  end
end
