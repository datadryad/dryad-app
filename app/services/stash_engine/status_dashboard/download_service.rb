# frozen_string_literal: true

module StashEngine
  module StatusDashboard

    class DownloadService < DependencyCheckerService

      def ping_dependency
        super
        # Get a small dataset
        identifier = StashEngine::Identifier.publicly_viewable.where.not(storage_size: nil).order(:storage_size).first
        record_status(online: false, message: 'No dataset available for download to perform test') unless identifier.present?
        resource = identifier.latest_resource_with_public_download
        online = resource.repo_queue_states.last.available_in_storage?
        msg = "Download service is reporting files for #{resource.identifier_str} are not available in storage" unless online
        msg += "Identifier ID: #{identifier.id}  Resource ID: #{resource.id}" unless online
        record_status(online: online, message: msg)
        online
      rescue StandardError => e
        record_status(online: false, message: e.to_s)
        false
      end

    end

  end
end
