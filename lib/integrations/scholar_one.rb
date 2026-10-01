module Integrations
  class ScholarOne
    BASE_URL = APP_CONFIG.scholar_one.api_base_url

    def initialize(scholar_one_site_name)
      @username = APP_CONFIG.scholar_one.username
      @password = APP_CONFIG.scholar_one.password
      @site_name = scholar_one_site_name

      @http = HTTPClient.new
      @http.set_auth(BASE_URL, @username, @password)
      @response = nil
    end

    def manuscript_metadata(submission_id)
      url = "#{BASE_URL}/api/s1m/v13/submissions/full/metadata/submissionids"

      @response = @http.get(url, request_args(submission_id))
      parsed_response
    end

    def authors_metadata(submission_id)
      url = "#{BASE_URL}/api/s1m/v3/submissions/full/contributors/authors/submissionids"

      @response = @http.get(url, request_args(submission_id))
      parsed_response
    end

    private

    def request_args(submission_id)
      {
        site_name: @site_name,
        locale_id: 1,
        ids: "'#{submission_id}'",
        _type: 'json'
      }
    end

    def parsed_response
      JSON.parse(@response.body).to_h.with_indifferent_access.dig(:Response, :result)
    rescue JSON::ParserError => e
      Rails.logger.error("Error parsing ScholarOne response: #{e.message}")
      {}
    end
  end
end
