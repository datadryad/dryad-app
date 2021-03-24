require 'faker'
require 'ostruct'
require 'byebug'

module StashEngine
  RSpec.describe CounterLogger, type: :model do

    include Mocks::CurationActivity

    # a general hit is anything that isn't a full version download
    context 'CounterLogger setup' do

      before(:each) do
        neuter_curation_callbacks!

        # mock the parts of request needed'
        @request = {
          remote_ip: Faker::Internet.ip_v4_address,
          session_options: { id: Faker::Number.number(digits: 10) },
          session: { 'user_id' => Faker::Number.number(digits: 10) },
          original_url: Faker::Internet.url,
          user_agent: Faker::Internet.user_agent
        }.to_ostruct

        # need resource, user, identifier
        @user = create(:user, role: nil)
        @identifier = create(:identifier)
        @resource = create(:resource, user_id: @user.id, identifier_id: @identifier.id, publication_date: Time.new)
        @publisher = create(:publisher, resource_id: @resource.id)
        @version = create(:version, resource_id: @resource.id)

        # sometimes need file
        @file = create(:data_file, resource_id: @resource.id, file_state: 'created')

        # returns the argument that was passed in (I think) for easier tests
        @line = nil
        allow(StashEngine).to receive(:counter_log) do |line|
          @line = line
        end

        # @line should be 18 long array (the timestamp not added yet) and it has these fields
        # 0:ip_address, 1:session_cookie (never set), 2:session_id, 3:user_id, 4:original_url, 5:identifier,
        # 6:filename, 7:size, 8:user_agent, 9:title, 10:publisher, 11:publisher_id, 12:authors, 13:publication_date,
        # 14:version, 15:other_id (always blank), 16:doi_url, 17:publication_year
      end

      context 'general_hit(request:, resource:, file:)' do

        it 'produces a correct output line with all data filled' do
          StashEngine::CounterLogger.general_hit(request: @request, resource: @resource, file: @file)
          expect(@line[0]).to eq(@request.remote_ip)
          expect(@line[1]).to eq(nil)
          expect(@line[2]).to eq(@request.session_options[:id])
          expect(@line[3]).to eq(@request.session['user_id'])
          expect(@line[4]).to eq(@request.original_url)
          expect(@line[5]).to eq(@identifier.to_s)
          expect(@line[6]).to eq(@file.upload_file_name)
          expect(@line[7]).to eq(@file.upload_file_size)
          expect(@line[8]).to eq(@request.user_agent)
          expect(@line[9]).to eq(@resource.title)
          expect(@line[10]).to eq(@publisher.publisher)
          expect(@line[11]).to eq(@resource.tenant.publisher_id)
          expect(@line[12]).to eq(@resource.authors.first.author_standard_name)
          expect(@line[13]).to eq(@resource.publication_date)
          expect(@line[14]).to eq(@resource.stash_version.version)
          expect(@line[15]).to eq('')
          expect(@line[16]).to eq(@identifier.target)
          expect(@line[17]).to eq(@resource.publication_date&.year)
        end

        it 'works fine without a file and leaves out some data' do
          StashEngine::CounterLogger.general_hit(request: @request, resource: @resource)
          expect(@line[0]).to eq(@request.remote_ip)
          expect(@line[1]).to eq(nil)
          expect(@line[2]).to eq(@request.session_options[:id])
          expect(@line[3]).to eq(@request.session['user_id'])
          expect(@line[4]).to eq(@request.original_url)
          expect(@line[5]).to eq(@identifier.to_s)
          expect(@line[6]).to eq(nil)
          expect(@line[7]).to eq(nil)
          expect(@line[8]).to eq(@request.user_agent)
          expect(@line[9]).to eq(@resource.title)
          expect(@line[10]).to eq(@publisher.publisher)
          expect(@line[11]).to eq(@resource.tenant.publisher_id)
          expect(@line[12]).to eq(@resource.authors.first.author_standard_name)
          expect(@line[13]).to eq(@resource.publication_date)
          expect(@line[14]).to eq(@resource.stash_version.version)
          expect(@line[15]).to eq('')
          expect(@line[16]).to eq(@identifier.target)
          expect(@line[17]).to eq(@resource.publication_date&.year)
        end

        it "doesn't send message to log when dataset has no publication date" do
          @resource.update(publication_date: nil)
          @resource.reload
          @file.reload
          StashEngine::CounterLogger.general_hit(request: @request, resource: @resource, file: @file)
          expect(@resource.publication_date).to eq(nil)
          expect(@file.resource.publication_date).to eq(nil)
          expect(@file.resource).to eq(@resource)
          expect(@line).to eq(nil) # because this was missing publication so can't be logged with incomplete data
        end

        it "doesn't send message to log when dataset has no title" do
          @resource.update(title: '')
          @resource.reload
          @file.reload
          StashEngine::CounterLogger.general_hit(request: @request, resource: @resource, file: @file)
          expect(@line).to eq(nil) # because this was missing publication so can't be logged with incomplete data
        end

        it "doesn't send message to log when dataset has no authors" do
          @resource.authors.first.update(author_first_name: '', author_last_name: '')
          @resource.reload
          StashEngine::CounterLogger.general_hit(request: @request, resource: @resource, file: @file)
          expect(@line).to eq(nil) # because this was missing publication so can't be logged with incomplete data
        end
      end

      context 'version_download_hit(request:, resource:)' do
        it 'produces a correct output line for a version download' do
          StashEngine::CounterLogger.version_download_hit(request: @request, resource: @resource)
          expect(@line[0]).to eq(@request.remote_ip)
          expect(@line[1]).to eq(nil)
          expect(@line[2]).to eq(@request.session_options[:id])
          expect(@line[3]).to eq(@request.session['user_id'])
          expect(@line[4]).to eq(@request.original_url)
          expect(@line[5]).to eq(@identifier.to_s)
          expect(@line[6]).to eq(nil)
          expect(@line[7]).to eq(@file.upload_file_size)
          expect(@line[8]).to eq(@request.user_agent)
          expect(@line[9]).to eq(@resource.title)
          expect(@line[10]).to eq(@publisher.publisher)
          expect(@line[11]).to eq(@resource.tenant.publisher_id)
          expect(@line[12]).to eq(@resource.authors.first.author_standard_name)
          expect(@line[13]).to eq(@resource.publication_date)
          expect(@line[14]).to eq(@resource.stash_version.version)
          expect(@line[15]).to eq('')
          expect(@line[16]).to eq(@identifier.target)
          expect(@line[17]).to eq(@resource.publication_date&.year)
        end
      end
    end
  end
end
