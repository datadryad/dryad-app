require 'rails_helper'
require_relative 'stash_api/helpers'
require 'byebug'

# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
module StashApi
  RSpec.describe ApiController, type: :request do
    before(:each) do
      @user = create(:user, role: 'superuser')
      host! 'my.example.org'
      @doorkeeper_application = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                owner_id: @user.id, owner_type: 'StashEngine::User')
      setup_access_token(doorkeeper_application: @doorkeeper_application)
    end

    describe '#test' do
      it 'returns welcome message and authenticated user id for good token' do
        post '/api/v2/test', headers: default_authenticated_headers
        hsh = response_body_hash
        expect(/Welcome application owner.+$/).to match(hsh[:message])
        expect(@user.id).to eql(hsh[:user_id])
      end

      it 'returns 401 unauthorized for non-authenticated user' do
        response_code = post '/api/v2/test', headers: default_json_headers
        expect(response_code).to eq(401) # unauthorized
        expect(/invalid_token/).to match(response.headers['WWW-Authenticate'])
      end
    end

    describe '#index' do
      it 'has a HATEOAS link to the main entry into API, the datasets list' do
        get '/api/v2/', headers: default_json_headers
        hsh = response_body_hash
        expect(hsh['_links']['stash:datasets']['href']).to eql('/api/v2/datasets')
      end
    end

    # rubocop:disable Lint/InterpolationCheck
    describe '#reports_index' do
      before do
        allow(Dir).to receive(:entries).and_return(%w[. .. report1.csv report2.csv])
      end

      it 'lists all the reports from REPORTS_DIR' do
        get '/api/v2/reports'
        hsh = response_body_hash

        expect(hsh['_links']['self']['href']).to eql('/api/v2/')
        expect(hsh['_links']['reports'].map { |a| a['href'] }).to match_array(%w[/api/v2/reports/report1 /api/v2/reports/report2])
        expect(hsh['_links']['curies']).to eq(
          [
            {
              'name' => 'stash',
              'href' => 'https://github.com/datadryad/dryad-app/blob/main/documentation/apis/link_relations.md#{rel}',
              'templated' => 'true'
            }
          ]
        )
      end
    end
    # rubocop:enable Lint/InterpolationCheck

    describe '#reports' do
      before do
        allow(Dir).to receive(:entries).and_return(%w[. .. report1.csv])
      end

      context 'when the report exists' do
        context 'when file does not exist' do
          before do
            allow(::File).to receive(:exist?).and_return(false)
          end

          it 'returns error' do
            stub_const('StashApi::ApiController::REPORTS_DIR', Rails.root.join('tmp', 'reports'))
            get '/api/v2/reports/report1'

            expect(response).to have_http_status(:unprocessable_entity)
            expect(response_body_hash[:error]).to eq('Unable to render report file for report1.csv')
          end
        end

        context 'when file exist' do
          let(:file_path) { Rails.root.join('tmp', 'reports', 'report1.csv') }

          before do
            stub_const('StashApi::ApiController::REPORTS_DIR', Rails.root.join('tmp', 'reports'))
            FileUtils.mkdir_p(::File.dirname(file_path))
            ::File.write(file_path, 'some,csv,data')
          end

          after do
            ::File.delete(file_path) if ::File.exist?(file_path)
          end

          it 'returns error if file does not exist' do
            get '/api/v2/reports/report1'

            d = Time.now.utc.to_date
            expected_filename = "report1_#{d.strftime('%Y%m%d')}.csv"

            expect(response.header['Content-Disposition']).to include("filename=\"#{expected_filename}\"")
            expect(response.content_type).to eq('text/plain')
            expect(response.body).to eq('some,csv,data')
          end
        end
      end

      context 'when the report is not found' do
        it 'returns 404 and error message' do
          get '/api/v2/reports/inexistent_report_name'

          expect(response.status).to eq(404)

          hsh = response_body_hash
          expect(hsh[:error]).to eq('Could not find requested report inexistent_report_name')
        end
      end
    end

    describe '#versioning' do
      before { post '/api/v2/test', headers: request_headers }

      context 'with no X-API-Version header' do
        context 'with current API version' do
          let(:request_headers) { default_authenticated_headers }

          it 'is successful and has correct response headers' do
            expect(response).to be_successful
            expect(response.headers['X-API-Version']).to eql('2.1.0')
            expect(response.headers['X-API-deprecation']).to be_nil
          end
        end
      end

      context 'with X-API-Version header' do
        context 'with current API version' do
          let(:request_headers) { default_authenticated_headers.merge('X-API-Version' => '2.1.0') }

          it 'is successful and has correct response headers' do
            expect(response).to be_successful
            expect(response.headers['X-API-Version']).to eql('2.1.0')
            expect(response.headers['X-API-Deprecation']).to be_nil
          end
        end

        context 'with old API version' do
          let(:request_headers) { default_authenticated_headers.merge('X-API-Version' => '1.0.0') }

          it 'returns 400 and has correct response headers' do
            expect(response.status).to eql(400)
            expect(response.headers['X-API-Version']).to eql('1.0.0')
            expect(response.headers['X-API-Deprecation']).to be_truthy
          end
        end

        context 'with bad API version' do
          let(:request_headers) { default_authenticated_headers.merge('X-API-Version' => 'bad version') }

          it 'returns 400 and has correct response headers' do
            expect(response.status).to eql(400)
            expect(response.headers['X-API-Version']).to eql('bad version')
            expect(response.headers['X-API-Deprecation']).to be_truthy
          end
        end
      end
    end
  end
end
