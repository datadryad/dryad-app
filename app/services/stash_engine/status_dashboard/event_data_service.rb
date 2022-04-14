# frozen_string_literal: true

module StashEngine
  module StatusDashboard

    class EventDataService < DependencyCheckerService

      def ping_dependency
        super
        resp = Stash::EventData::Usage.ping
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
