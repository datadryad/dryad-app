module Integrations
  class ScholarOne
    BASE_URL = APP_CONFIG.scholar_one.api_base_url
    SITE_NAME = 'supportdemoplus'.freeze

    def initialize
      @username = APP_CONFIG.scholar_one.username
      @password = APP_CONFIG.scholar_one.password

      @http = HTTPClient.new

      @http.set_auth(
        BASE_URL,
        @username,
        @password
      )
      @response = nil
    end

    def manuscript_metadata(submission_id)
      url = "#{BASE_URL}/api/s1m/v13/submissions/full/metadata/submissionids"

      @response = @http.get(
        url,
        request_args(submission_id)
      )

      parsed_response
    end

    private

    def request_args(submission_id)
      {
        site_name: SITE_NAME,
        locale_id: 1,
        ids: "'#{submission_id}'",
        _type: 'json'
      }
    end

    def parsed_response
      JSON.parse(@response.body).to_h.with_indifferent_access.dig(:Response, :result)
    end
  end
end
