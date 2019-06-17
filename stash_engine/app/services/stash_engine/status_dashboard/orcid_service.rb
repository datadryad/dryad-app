# frozen_string_literal: true

require 'httparty'

module StashEngine
  module StatusDashboard

    class OrcidService < DependencyCheckerService

      def ping_dependency
        super
        # Check the status of the ORCID API
        target = StashEngine.app.orcid.token_url
        resp = HTTParty.get(target)
        # We are pinging one of the ORCID auth endpoints so expect a 401
        online = resp.code == 401
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
