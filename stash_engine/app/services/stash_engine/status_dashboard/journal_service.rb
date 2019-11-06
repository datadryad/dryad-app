# frozen_string_literal: true

require 'httparty'
require 'cgi'

module StashEngine
  module StatusDashboard

    class JournalService < DependencyCheckerService

      def ping_dependency
        super
        # Check the status of the ORCID API
        issn = StashEngine::InternalDatum.where(data_type: 'publicationISSN').last
        target = "#{APP_CONFIG.old_dryad_url}/api/v1/organizations/#{CGI.escape(issn&.value)}/manuscripts" # /#{CGI.escape(manuscript&.value)}"
        resp = HTTParty.get(target,
                            query: { access_token: APP_CONFIG.old_dryad_access_token },
                            headers: { 'Content-Type' => 'application/json' })
        online = resp.code == 200
        msg = resp.body unless online
        record_status(online: online, message: msg)
        online
      rescue StandardError => e
        record_status(online: false, message: e.to_s)
        false
      end

    end

  end
end
