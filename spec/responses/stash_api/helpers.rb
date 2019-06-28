require 'json'

module Helpers

  RSpec.configure do |config|
    config.render_views = true
    config.include Helpers
  end

  def get_access_token(doorkeeper_application:)
    post '/oauth/token',
         { grant_type: 'client_credentials', client_id: doorkeeper_application.uid, client_secret: doorkeeper_application.secret },
         default_json_headers.merge('Content-type' => 'application/x-www-form-urlencoded;charset=UTF-8')
    response_body_hash[:access_token]
  end

  def setup_access_token(doorkeeper_application:)
    @access_token = get_access_token(doorkeeper_application: doorkeeper_application)
  end

  def response_body_hash
    return {} if response.body.blank?
    JSON.parse(response.body).with_indifferent_access
  end

  def default_json_headers
    { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
  end

  def default_authenticated_headers
    default_json_headers.merge('Authorization' => "Bearer #{@access_token}")
  end

end
