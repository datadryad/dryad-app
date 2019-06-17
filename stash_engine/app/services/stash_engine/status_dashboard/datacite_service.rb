# frozen_string_literal: true

module StashEngine
  module StatusDashboard

    class DataciteService < DependencyCheckerService

      def ping_dependency
        super
        dataset = StashEngine::Identifier.where.not(identifier: nil).last
        svc = Stash::Doi::DataciteGen.new(resource: dataset.latest_resource)
        resp = svc.ping(dataset.identifier)
        # If we did not get any errors OR we got a 404 (Datacite may not yet have the dataset's metadata)
        online = !resp['errors'].present? || resp['errors'].first['status'] == 404
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
