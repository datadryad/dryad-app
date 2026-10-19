module Integrations
  class ScholarOne
    BASE_URL = APP_CONFIG.scholar_one.api_base_url

    attr_reader :resource, :status

    def initialize(journal, resource = nil, status = nil)
      @resource = resource
      @status = status

      integration = journal.external_integrations.scholarone.first
      @site_name = integration.details['site_name']

      @http = HTTPClient.new
      @http.set_auth(BASE_URL, integration.username, integration.password)
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

    def relay_notification
      document_id = submission_document_id
      puts "Sending relay call for #{document_id}, resource #{resource.id}, version #{resource.stash_version.version}, status: #{status}"
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
          body: relay_call_body(document_id),
          header: {
            'Content-Type' => 'application/json',
            'Accept' => 'application/json'
          }
        }
      )

      resp = parsed_response
      puts("Relay API successfully called for #{resource.id}") if resp['returnCode'].downcase == 'ok'
      resp
    end

    def submission_document_id
      manuscript_number = resource.resource_publication.manuscript_number
      return if manuscript_number.blank?

      manu = StashEngine::Manuscript.where(manuscript_number: manuscript_number, identifier_id: resource.identifier_id).first
      manu ||= StashEngine::Manuscript.where(manuscript_number: manuscript_number, journal_id: resource.journal.id).first

      if manu.blank?
        metadata = manuscript_metadata(manuscript_number)
        manu = Manuscript::ScholarOneService.new(metadata, resource.identifier).process
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

    def relay_call_body(document_id)
      {
        data: {
          type: 2,
          payload: {
            documentId: document_id,
            content: html_content,
            checkType: 1111,
            url: dataset_url,
            effectiveDate: 1.year.from_now.to_date.to_s,
            score: resource.stash_version.version,
            alert: 'false'
          }
        }
      }.to_json
    end

    def html_content
      <<-TEXT.squish.squeeze(' ')
  <p><strong>Dryad dataset available</strong></p>
  <p>Dataset status: #{StashEngine::CurationActivity.readable_status(status)}</p>
  <p>Dataset title: #{resource.title}</p>
  <p>Reviewer link: <a href="#{resource.identifier&.shares&.first&.sharing_link}">#{resource.identifier&.shares&.first&.sharing_link}</a></p>
  <p>Permanent identifier: <a href="#{resource.identifier.identifier_uri}">#{resource.identifier.identifier_uri}</a></p>
      TEXT
    end

    def dataset_url
      if resource.identifier.published? && resource.last_curation_activity.status.in?(%w[published embargoed retracted])
        return resource.identifier.identifier_uri
      end

      resource.identifier&.shares&.first&.sharing_link
    end
  end
end
