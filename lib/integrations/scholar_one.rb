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

    def relay_notification(resource)
      document_id = submission_document_id(resource)
      return if document_id.blank?

      url = "#{BASE_URL}/api/s1m/v2/system/addJSONData"
      params = {
        site_name: @site_name,
        locale_id: 1,
        external_id: resource.identifier.identifier,
        _type: 'json'
      }

      @response = @http.post(
        url,
        {
          query: params,
          body: relay_call_body(resource, document_id),
          header: {
            'Content-Type' => 'application/json',
            'Accept' => 'application/json'
          }
        }
      )

      resp = parsed_response
      Rails.logger.info("Relay API successfully called for #{resource.id}") if resp['returnCode'] == 'OK'
      resp
    end

    def submission_document_id(resource)
      manuscript_number = resource.resource_publication.manuscript_number
      manu = StashEngine::Manuscript.where(manuscript_number: manuscript_number, identifier_id: resource.identifier_id).first
      manu ||= StashEngine::Manuscript.where(manuscript_number: manuscript_number, journal_id: resource.journal.id).first

      if manu.blank?
        metadata = manuscript_metadata(manuscript_number)
        manu = Manuscript::ScholarOneService.new(metadata, resource.identifier).create
      end
      return if manu.blank?

      manu.metadata[:documentId]
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

    def relay_call_body(resource, document_id)
      {
        data: {
          type: 2,
          payload: {
            documentId: document_id,
            content: resource.title,
            checkType: 1111,
            url: resource.identifier&.shares&.first&.sharing_link,
            effectiveDate: 1.year.from_now.to_date.to_s,
            score: resource.stash_version.version,
            alert: 'false'
          }
        }
      }.to_json
    end
  end
end
