# frozen_string_literal: true

require 'httparty'

module StashEngine
  module StatusDashboard

    class DownloadService < DependencyCheckerService

      def ping_dependency
        super
        # Get a small dataset
        identifier = StashEngine::Identifier.publicly_viewable.where.not(storage_size: nil).order(:storage_size).first
        record_status(online: false, message: 'No dataset available for download to perform test') unless identifier.present?
        file = identifier.latest_resource_with_public_download.data_files.order(:upload_file_size).first
        url = file.s3_permanent_presigned_url(head_only: true)
        resp = HTTParty.head(url, follow_redirect: true, maintain_method_across_redirects: true)
        online = resp.code == 200
        msg = "Download service is reporting an HTTP #{resp.code}!" unless online
        msg += resp.body if !online && resp.body.present?
        record_status(online: online, message: msg)
        online
      rescue StandardError => e
        record_status(online: false, message: e.to_s)
        false
      end

    end

  end
end
