require 'rails_helper'

module StashEngine
  RSpec.describe ApiToken, type: :model do

    before(:each) do
      @api_token = create(:api_token)

      @new_token = Faker::Internet.uuid
      stub_request(:post, "http://localhost:3000/oauth/token").
        with(
          body: "{\"client_id\":\"#{@api_token.app_id}\",\"client_secret\":\"#{@api_token.secret}\"," \
        "\"grant_type\":\"client_credentials\"}",
          headers: {'Content-Type'=>'application/json; charset=UTF-8' })
                                                              .to_return(status: 200,
                                                                         body: {'access_token' => @new_token,
                                                                                'expires_in' => 6000}.to_json,
                                                                         headers: { 'Content-Type' => 'application/json' })
    end

    describe '#new_token' do
      it 'gets a new token from the API' do
        @old_api_token = @api_token.clone
        @api_token.new_token
        @api_token.reload
        expect(@old_api_token.app_id).to eql(@api_token.app_id)
        expect(@old_api_token.secret).to eql(@api_token.secret)
        expect(@api_token.token).to eql(@new_token)
        expect(@api_token.expires_at).to be_between(Time.new + 5990, Time.new + 6010)
      end
    end

    describe ".token" do
      it 'creates a new token for a soon expiring one' do
        expect(ApiToken.token).to eq(@new_token)
      end

      it 'keeps old token for one not expiring for hours' do
        old_token = @api_token.token
        @api_token.update(expires_at: Time.new + 3.hours)
        expect(ApiToken.token).to eql(old_token)
      end
    end
  end
end
