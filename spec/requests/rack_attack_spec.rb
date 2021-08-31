require 'rails_helper'

RSpec.describe 'Rack::Attack', type: :request do
  # Include time helpers to allow use to use travel_to
  # within RSpec
  include ActiveSupport::Testing::TimeHelpers

  before do
    # Enable Rack::Attack for this test
    Rack::Attack.enabled = true
    Rack::Attack.reset!
  end

  after do
    # Disable Rack::Attack for future tests so it doesn't
    # interfere with the rest of our tests
    Rack::Attack.enabled = false
  end

  describe 'GET homepage' do
    # Set the headers, if you'd blocking specific IPs you can change
    # this programmatically.
    let(:headers) { { 'REMOTE_ADDR' => '1.2.3.4' } }

    it 'succeeds initially, blocks after too many attempts, then allows afteer time passes' do
      freeze_time do
        120.times do
          get '/stash', headers: headers
          expect(response).to have_http_status(:success)
        end

        get '/stash', headers: headers
        expect(response).to have_http_status(:too_many_requests)
      end

      travel_to(2.minutes.from_now) do
        get '/stash', headers: headers
        expect(response).to have_http_status(:success)
      end
    end

    it 'forbids users from visiting a malicious path, then blocks user from whole site' do
      freeze_time do
        get '/etc/passwd', headers: headers
        expect(response).to have_http_status(:forbidden)
      end
      # Banned from the rest of the site
      get '/stash', headers: headers
      expect(response).to have_http_status(:forbidden)
      # Resets after days
      travel_to(2.days.from_now) do
        get '/stash', headers: headers
        expect(response).to have_http_status(:success)
      end
    end

  end
end
