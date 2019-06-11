# frozen_string_literal: true

module StashEngine
  module StatusDashboard

    class CrossrefService < DependencyCheckerService

      def ping_dependency
        super
        # Check the status of the Crossref API via the Serrano gem
        works = Serrano.works(ids: StashEngine::Identifier.publicly_viewable.last&.identifier)
        online = (works.is_a?(Array) && works.first['message'].blank?)
        msg = "We couldn't obtain information from CrossRef about this DOI" unless online
        record_status(online: online, message: msg)
        online
      rescue Serrano::NotFound
        # A 404 does not mean the service is offline!
        record_status(online: true, message: nil)
        true
      rescue StandardError => e
        record_status(online: false, message: e.to_s)
        false
      end

    end

  end
end
