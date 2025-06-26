# require 'tmpdir'
# require 'concurrent'
# require 'fileutils'
#
# module Stash
#   module Repo
#     describe Repository do
#       include Mocks::Aws
#       include Mocks::Datacite
#       include Mocks::CurationActivity
#       include Mocks::Salesforce
#
#       attr_reader :doi_value
#       attr_reader :identifier
#       attr_reader :logger
#       attr_reader :public_system
#       attr_reader :rails_root
#       attr_reader :record_identifier
#       attr_reader :repo
#       attr_reader :resource
#       attr_reader :resource_id
#       attr_reader :res_upload_dir
#       attr_reader :tenant
#       attr_reader :uploads
#
#       context 'high-level repo tests' do
#         before(:each) do
#           @repo = Repository.new(executor: Concurrent::ImmediateExecutor.new, threads: 1)
#
#           @logger = instance_double(Logger)
#           allow(Rails).to receive(:logger).and_return(logger)
#           allow(logger).to receive(:info)
#
#           @rails_root = Dir.mktmpdir('rails_root')
#           root_path = Pathname.new(rails_root)
#           allow(Rails).to receive(:root).and_return(root_path)
#
#           public_path = Pathname.new("#{rails_root}/public")
#           allow(Rails).to receive(:public_path).and_return(public_path)
#
#           immediate_executor = Concurrent::ImmediateExecutor.new
#           allow(Concurrent).to receive(:global_io_executor).and_return(immediate_executor)
#
#           allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_now)
#
#           @resource_id = 53
#           @resource = double(StashEngine::Resource)
#           allow(resource).to receive(:id).and_return(resource_id)
#           allow(resource).to receive(:current_state=)
#           allow(resource).to receive(:skip_emails).and_return(false)
#           allow(StashEngine::Resource).to receive(:find).with(resource_id).and_return(resource)
#
#           @res_upload_dir = Dir.mktmpdir
#           allow(StashEngine::Resource).to receive(:upload_dir_for).with(resource_id).and_return(res_upload_dir)
#
#           @uploads = Array.new(3) do |index|
#             upload = double(StashEngine::DataFile)
#             calc_file_path = File.join(res_upload_dir, "file-#{index}.bin")
#             FileUtils.touch(calc_file_path)
#             allow(upload).to receive(:calc_file_path).and_return(calc_file_path)
#             upload
#           end
#           allow(resource).to receive(:data_files).and_return(uploads)
#         end
#
#         after(:each) do
#           allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_now).and_call_original
#           allow(Concurrent).to receive(:global_io_executor).and_call_original
#           allow(Rails).to receive(:logger).and_call_original
#           FileUtils.remove_dir(rails_root)
#         end
#
#         describe :create_submission_job do
#           xit 'is abstract' do
#             expect { repo.create_submission_job(resource_id: 17) }.to raise_error(NoMethodError)
#           end
#         end
#
#         describe :download_uri_for do
#           xit 'is abstract' do
#             expect { repo.download_uri_for(record_identifier: 'ark:/1234/567') }.to raise_error(NoMethodError)
#           end
#         end
#
#         describe :update_uri_for do
#           xit 'is abstract' do
#             expect { repo.update_uri_for(resource: resource, record_identifier: 'ark:/1234/567') }.to raise_error(NoMethodError)
#           end
#         end
#
#         describe :submit do
#           attr_reader :job
#
#           before(:each) do
#             @request_host = 'stash.example.org'
#             @request_port = 80
#
#             @job = SubmissionJob.new(resource_id: resource_id)
#             expected_id = resource_id
#             returned_job = job
#             repo.define_singleton_method(:create_submission_job) do |params|
#               raise ArgumentError unless params[:resource_id] == expected_id
#
#               returned_job
#             end
#
#             allow(StashEngine::SubmissionLog).to receive(:create)
#           end
#
#           after(:each) do
#             FileUtils.remove_entry_secure(res_upload_dir) if File.directory?(res_upload_dir)
#           end
#
#           def submit_resource
#             repo.submit(resource_id: resource_id)
#           end
#
#           describe :handle_success do
#             before(:each) do
#               allow(job).to receive(:submit!).and_return(SubmissionResult.new(resource_id: resource_id, request_desc: 'test', message: 'whee!'))
#               allow(job).to receive(:description).and_return('test')
#             end
#
#             it 'leaves the state as "processing"' do
#               expect(resource).to receive(:current_state=).with('processing')
#               expect(resource).not_to receive(:current_state=).with('submitted')
#               submit_resource
#             end
#
#             it 'updates the submission log table' do
#               expect(StashEngine::SubmissionLog).to receive(:create).with(
#                 resource_id: resource_id,
#                 archive_submission_request: 'test',
#                 archive_response: 'whee!'
#               )
#               submit_resource
#             end
#
#             it 'updates the RepoQueueState table)' do
#               expect(StashEngine::RepoQueueState).to receive(:create).with(
#                 resource_id: resource_id,
#                 hostname: repo.class.hostname,
#                 state: 'enqueued'
#               )
#               submit_resource
#             end
#
#             describe 'when result.deferred? = true' do
#               it "doesn't update repo queue states with success" do
#                 result = SubmissionResult.new(resource_id: resource_id, request_desc: 'test', message: 'whee!')
#                 result.deferred = true
#                 allow(job).to receive(:submit!).and_return(result)
#
#                 expect(StashEngine::RepoQueueState).to receive(:create).with(
#                   resource_id: resource_id,
#                   hostname: repo.class.hostname,
#                   state: 'enqueued'
#                 )
#                 expect(StashEngine::RepoQueueState).not_to receive(:create).with(
#                   resource_id: resource_id,
#                   hostname: repo.class.hostname,
#                   state: 'completed'
#                 )
#                 submit_resource
#               end
#             end
#
#             describe 'unexpected errors' do
#               before(:each) do
#                 allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_now).and_raise(Net::SMTPAuthenticationError)
#               end
#               # We moved the success email to the curation_activity so this error does not fire
#               # TODO: find another suitable method to raise the error on
#               xit 'logs the error' do
#                 msg = nil
#                 expect(logger).to(receive(:error)).once { |m| msg = m }
#                 submit_resource
#                 expect(msg).to include(resource_id.to_s)
#                 expect(msg).to include(Net::SMTPAuthenticationError.to_s)
#               end
#
#               it 'leaves uploaded files in place on failure' do
#                 submit_resource
#                 uploads.each do |upload|
#                   expect(File.exist?(upload.calc_file_path)).to be_truthy
#                 end
#               end
#
#               it 'leaves the uploads dir in place on failure' do
#                 submit_resource
#                 expect(File.exist?(res_upload_dir)).to be_truthy
#               end
#
#               it 'leaves the state as "processing"' do
#                 expect(resource).to receive(:current_state=).with('processing')
#                 expect(resource).not_to receive(:current_state=).with('submitted')
#                 submit_resource
#               end
#
#               it 'updates the submission log table' do
#                 expect(StashEngine::SubmissionLog).to receive(:create).with(
#                   resource_id: resource_id,
#                   archive_submission_request: 'test',
#                   archive_response: 'whee!'
#                 )
#                 submit_resource
#               end
#             end
#           end
#
#           describe :handle_failure do
#             before(:each) do
#               allow(job).to receive(:submit!).and_raise(ActiveRecord::ConnectionTimeoutError)
#               allow(job).to receive(:description).and_return('test')
#               allow(logger).to receive(:error)
#             end
#
#             it 'sends an error report email' do
#               message = instance_double(ActionMailer::MessageDelivery)
#               expect(StashEngine::UserMailer).to receive(:error_report)
#                 .with(resource, kind_of(ActiveRecord::ConnectionTimeoutError))
#                 .and_return(message)
#               expect(message).to receive(:deliver_now)
#               submit_resource
#             end
#
#             it 'logs the error' do
#               msg = nil
#               expect(logger).to(receive(:error)).once { |m| msg = m }
#               submit_resource
#               expect(msg).to include(resource_id.to_s)
#               expect(msg).to include(ActiveRecord::ConnectionTimeoutError.to_s)
#             end
#
#             it 'leaves uploaded files in place on failure' do
#               submit_resource
#               uploads.each do |upload|
#                 expect(File.exist?(upload.calc_file_path)).to be_truthy
#               end
#             end
#
#             it 'leaves the uploads dir in place on success' do
#               submit_resource
#               expect(File.exist?(res_upload_dir)).to be_truthy
#             end
#
#             it 'sets the state to failed' do
#               expect(resource).to receive(:current_state=).with('processing')
#               expect(resource).to receive(:current_state=).with('error')
#               submit_resource
#             end
#
#             it 'updates the submission log table' do
#               expect(StashEngine::SubmissionLog).to receive(:create).with(
#                 resource_id: resource_id,
#                 archive_submission_request: 'test',
#                 archive_response: ActiveRecord::ConnectionTimeoutError.to_s
#               )
#               submit_resource
#             end
#
#             describe 'unexpected errors' do
#               before(:each) do
#                 puts :deliver_now
#                 allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_now).and_raise(Net::SMTPAuthenticationError.new('error'))
#               end
#
#               it 'logs the error' do
#                 msg = nil
#                 expect(logger).to(receive(:error)).twice { |m| msg = m }
#                 submit_resource
#                 # depending on which version of the gem is used, sometimes it logs the real error, and sometimes
#                 # just sends two SMTPAuthenticationErrors. If it switches back you might have to use this test instead of the
#                 # AuthenticationError tests...
#                 # expect(msg).to include(resource_id.to_s)
#
#                 # There is a method called handle_failure in repo/repository.rb that mails on the errors and it seems like
#                 # this mock (before above) is now intercepting the call in there where it wasn't before on the first try.
#                 # IDK, why it does it twice.
#                 expect(msg).to include(Net::SMTPAuthenticationError.to_s)
#                 expect(msg).to include(Net::SMTPAuthenticationError.to_s)
#               end
#
#               it 'leaves uploaded files in place on failure' do
#                 submit_resource
#                 uploads.each do |upload|
#                   expect(File.exist?(upload.calc_file_path)).to be_truthy
#                 end
#               end
#
#               it 'leaves the uploads dir in place on success' do
#                 submit_resource
#                 expect(File.exist?(res_upload_dir)).to be_truthy
#               end
#
#               it 'sets the state to failed' do
#                 expect(resource).to receive(:current_state=).with('processing')
#                 expect(resource).to receive(:current_state=).with('error')
#                 submit_resource
#               end
#
#               it 'updates the submission log table' do
#                 expect(StashEngine::SubmissionLog).to receive(:create).with(
#                   resource_id: resource_id,
#                   archive_submission_request: 'test',
#                   archive_response: ActiveRecord::ConnectionTimeoutError.to_s
#                 )
#                 submit_resource
#               end
#             end
#           end
#         end
#
#         describe :harvested do
#           attr_reader :resource
#           attr_reader :identifier
#           attr_reader :record_identifier
#
#           before(:each) do
#             @download_location = 'some_s3_dir'
#             @identifier = double(StashEngine::Identifier)
#             allow(identifier).to receive(:processing_resource).and_return(resource)
#             allow(resource).to receive(:identifier).and_return(@identifier)
#             allow(resource).to receive(:s3_dir_name).and_return(@download_location)
#
#             @record_identifier = 'ark:/1234/567'
#
#             def repo.update_uri_for(_)
#               'http://example.org/edit/ark:/1234/567'
#             end
#
#             def repo.download_uri_for(_)
#               'http://example.org/d/ark:/1234/567'
#             end
#
#             allow(logger).to receive(:debug)
#             allow(resource).to receive(:update_uri=)
#             allow(resource).to receive(:download_uri=)
#             allow(resource).to receive(:save)
#             allow(resource).to receive(:data_files).and_return([])
#           end
#
#           it 'sets the download and update URIs' do
#             expect(resource).to receive(:download_uri=).with(@download_location)
#             repo.harvested(resource: resource)
#           end
#
#           it 'sets the state' do
#             expect(resource).to receive(:current_state=).with('submitted')
#             repo.harvested(resource: resource)
#           end
#
#           it 'saves the resource' do
#             expect(resource).to receive(:save)
#             repo.harvested(resource: resource)
#           end
#         end
#
#         describe 'Repository#update_repo_queue_state' do
#           it 'creates a queuestate in the database' do
#             expect(StashEngine::RepoQueueState).to receive(:create)
#             repo.class.update_repo_queue_state(resource_id: resource_id, state: 'rejected_shutting_down')
#           end
#         end
#
#         describe 'Repository#hostname' do
#           it "caches and returns the machine's hostname" do
#             expect(repo.class.hostname).to eq(`hostname`.strip)
#           end
#         end
#
#         describe 'Repository#hold_submissions?' do
#           it 'returns false in normal circumstances' do
#             expect(repo.class.hold_submissions?).to be false
#           end
#
#           it 'returns true if a hold-submissions.txt file is in place' do
#             file_path = File.expand_path(File.join(Rails.root, '..', 'hold-submissions.txt'))
#             ::FileUtils.touch(file_path)
#             expect(repo.class.hold_submissions?).to eq(true)
#             ::FileUtils.rm(file_path)
#           end
#         end
#       end
#
#       context 'old Merritt-level tests' do
#         before(:each) do
#           mock_datacite!
#           mock_aws!
#           mock_salesforce!
#
#           @rails_root = Dir.mktmpdir('rails_root')
#           root_path = Pathname.new(rails_root)
#           allow(Rails).to receive(:root).and_return(root_path)
#
#           public_path = Pathname.new("#{rails_root}/public")
#           allow(Rails).to receive(:public_path).and_return(public_path)
#
#           @public_system = public_path.join('system').to_s
#           FileUtils.mkdir_p(public_system)
#
#           user = StashEngine::User.create(
#             first_name: 'Lisa',
#             last_name: 'Muckenhaupt',
#             email: 'lmuckenhaupt@example.edu',
#             tenant_id: 'dataone'
#           )
#
#           repo_config = OpenStruct.new(
#             domain: 'http://storagetest.datadryad.org',
#             endpoint: 'http://storagetest.datadryad.org:39001/test/collection/dataone_dash'
#           )
#
#           @tenant = double(StashEngine::Tenant)
#           allow(@tenant).to receive(:tenant_id).and_return('dataone')
#           allow(@tenant).to receive(:short_name).and_return('DataONE')
#           allow(@tenant).to receive(:repository).and_return(repo_config)
#           allow(StashEngine::Tenant).to receive(:find).with('dataone').and_return(tenant)
#
#           stash_wrapper_xml = File.read('spec/data/archive/stash-wrapper.xml')
#           stash_wrapper = Stash::Wrapper::StashWrapper.parse_xml(stash_wrapper_xml)
#
#           datacite_xml = File.read('spec/data/archive/mrt-datacite.xml')
#           dcs_resource = Datacite::Mapping::Resource.parse_xml(datacite_xml)
#
#           @resource = StashDatacite::ResourceBuilder.new(
#             user_id: user.id,
#             dcs_resource: dcs_resource,
#             stash_files: stash_wrapper.inventory.files,
#             upload_date: stash_wrapper.version_date,
#             tenant_id: 'dataone'
#           ).build
#           @resource.current_state = 'processing'
#           @resource.save
#           @identifier = resource.identifier
#
#           @doi_value = '10.15146/R3RG6G'
#           expect(@resource.identifier_value).to eq(doi_value) # just to be sure
#
#           @record_identifier = 'http://n2t.net/ark:/99999/fk43f5119b'
#
#           @repo = Repository.new
#
#           log = instance_double(Logger)
#           allow(log).to receive(:debug)
#           allow(Rails).to receive(:logger).and_return(log)
#         end
#
#         after(:each) do
#           FileUtils.remove_dir(rails_root)
#         end
#
#         describe :create_submission_job do
#           it 'creates a submission job' do
#             repo = Repository.new(threads: 1)
#             resource_id = 17
#             job = repo.create_submission_job(resource_id: resource_id)
#             expect(job).to be_a(SubmissionJob)
#             expect(job.resource_id).to eq(resource_id)
#           end
#         end
#
#         describe :download_uri_for do
#           it 'determines the download URI' do
#             expected_uri = 'https://merritt-test.example.org/d/ark%3A%2F99999%2Ffk43f5119b'
#             actual_uri = repo.download_uri_for(record_identifier: record_identifier)
#             expect(actual_uri).to eq(expected_uri)
#           end
#         end
#
#         describe :harvested do
#           it 'sets the download URI and status' do
#             # Skip sending emails
#             @resource.skip_emails = true
#             @resource.save
#             neuter_curation_callbacks!
#             repo.harvested(resource: @resource)
#             @resource.reload
#             expect(@resource.download_uri).to include("-#{@resource.id}/data")
#             expect(@resource.current_state).to eq('submitted')
#           end
#         end
#
#         describe :cleanup_files do
#           it 'cleans up public/system files' do
#             resource_public = "#{public_system}/#{resource.id}"
#             FileUtils.mkdir(resource_public)
#             stash_wrapper = "#{resource_public}/stash-wrapper.xml"
#             some_other_file = "#{resource_public}/foo.bar"
#
#             FileUtils.touch(stash_wrapper)
#             FileUtils.touch(some_other_file)
#
#             repo.cleanup_files(resource)
#
#             [resource_public, stash_wrapper, some_other_file].each do |f|
#               expect(File.exist?(f)).to be_falsey
#             end
#           end
#         end
#
#       end
#
#     end
#   end
# end
