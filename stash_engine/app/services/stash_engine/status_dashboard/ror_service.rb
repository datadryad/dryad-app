# frozen_string_literal: true

module StashEngine
  module StatusDashboard

    class RorService < DependencyCheckerService

      def ping_dependency
        super
        # Check the status of the ROR API
        online = Stash::Organization::Ror.ping
        msg = 'The ROR API heartbeat is reporting that the API is offline.' unless online
        record_status(online: online, message: msg)
        online
      rescue StandardError => e
        record_status(online: false, message: e.to_s)
        false
      end

    end

  end
end
