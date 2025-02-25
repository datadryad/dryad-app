require 'rails_helper'

RSpec.describe 'Rack::Attack', type: :request do
  # Include time helpers to allow use to use travel_to
  # within RSpec
  include ActiveSupport::Testing::TimeHelpers

  before do
    # Enable Rack::Attack for this test
    Rack::Attack.enabled = true
    Rack::Attack.reset!
    create(:tenant)
  end

  after do
    # Disable Rack::Attack for future tests so it doesn't
    # interfere with the rest of our tests
    Rack::Attack.enabled = false
  end

  describe 'rack-attack limiting' do
    let(:headers) { { REMOTE_ADDR: '1.2.3.4' } }

    let(:badheaders) do
      { REMOTE_ADDR: '1.2.3.4',
        ACCEPT: '${${r:-j}${81p:-n}${i:-d}${cq:eg7c:yk4d:-i}${kpi:h0x:-:}${k:h:-l}${8:f5:-d}}' }
    end

    it 'limits basic page access' do
      # succeeds initially, blocks after too many attempts, then allows afteer time passes
      target_url = '/'
      freeze_time do
        APP_CONFIG[:rate_limit][:all_requests].times do
          get target_url, headers: headers
          expect(response).to have_http_status(:success)
        end

        get target_url, headers: headers
        expect(response).to have_http_status(:too_many_requests)
      end

      travel_to(2.minutes.from_now) do
        get target_url, headers: headers
        expect(response).to have_http_status(:success)
      end
    end

    it 'throttles anonymous API access' do
      target_url = '/api/v2/datasets'
      freeze_time do
        APP_CONFIG[:rate_limit][:api_requests_anon].times do
          get target_url, headers: headers
          expect(response).to have_http_status(:success)
        end

        get target_url, headers: headers
        expect(response).to have_http_status(:too_many_requests)
      end

      travel_to(2.minutes.from_now) do
        get target_url, headers: headers
        expect(response).to have_http_status(:success)
      end
    end

    it 'throttles authenticated API access' do
      auth_headers = { REMOTE_ADDR: '1.2.3.4',
                       HTTP_AUTHORIZATION: 'abc' }
      target_url = '/api/v2/datasets'
      freeze_time do
        APP_CONFIG[:rate_limit][:api_requests_auth].times do
          get target_url, headers: auth_headers
          expect(response).to have_http_status(:success)
        end

        get target_url, headers: auth_headers
        expect(response).to have_http_status(:too_many_requests)
      end

      travel_to(2.minutes.from_now) do
        get target_url, headers: auth_headers
        expect(response).to have_http_status(:success)
      end
    end

    it 'throttles download of zip files' do
      target_url = '/downloads/download_resource/BOGUS'
      freeze_time do
        APP_CONFIG[:rate_limit][:zip_downloads_per_hour].times do
          get target_url, headers: headers
          expect(response).to have_http_status(:not_found)
        end

        get target_url, headers: headers
        expect(response).to have_http_status(:too_many_requests)
      end

      travel_to(2.hours.from_now) do
        get target_url, headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end

    it 'throttles download of zip files for old /"stash/..." paths too' do
      target_url = '/stash/downloads/download_resource/BOGUS'
      freeze_time do
        APP_CONFIG[:rate_limit][:zip_downloads_per_hour].times do
          get target_url, headers: headers
          follow_redirect!
          expect(response).to have_http_status(:not_found)
        end

        get target_url, headers: headers
        expect(response).to have_http_status(:too_many_requests)
      end

      travel_to(2.hours.from_now) do
        get target_url, headers: headers
        follow_redirect!
        expect(response).to have_http_status(:not_found)
      end
    end

    it 'forbids users from visiting a malicious path, then blocks user from whole site' do
      freeze_time do
        get '/etc/passwd', headers: headers
        expect(response).to have_http_status(:forbidden)
      end
      # Banned from the rest of the site
      get '/', headers: headers
      expect(response).to have_http_status(:forbidden)
      # Resets after days
      travel_to(2.months.from_now) do
        get '/', headers: headers
        expect(response).to have_http_status(:success)
      end
    end

    it 'tells users about 2 bad requests, then blocks user from whole site' do
      freeze_time do
        2.times do
          get '/', headers: badheaders
          puts response.status
          puts response.body
          expect(response).to have_http_status(:bad_request)
        end
      end
      # Banned from the rest of the site
      get '/', headers: headers
      expect(response).to have_http_status(:forbidden)
      # Resets after days
      travel_to(2.days.from_now) do
        get '/', headers: headers
        expect(response).to have_http_status(:success)
      end
    end

    # honeypot for bad robots
    it 'blocks access for 1 month to whole site after 1 requests' do
      freeze_time do
        get pots_url, headers: headers
        expect(response).to have_http_status(:success)

        get pots_url, headers: headers
        expect(response).to have_http_status(:forbidden)
      end

      travel_to(25.days.from_now) do
        get pots_url, headers: headers
        expect(response).to have_http_status(:forbidden)
      end

      travel_to(35.days.from_now) do
        get pots_url, headers: headers
        expect(response).to have_http_status(:success)
      end
    end
  end
end
