# frozen_string_literal: true

require 'httparty'
require 'stash/repo/http_client'

module StashEngine
  module StatusDashboard

    class DownloadService < DependencyCheckerService

      def ping_dependency
        super
        # Get a small dataset
        identifier = StashEngine::Identifier.publicly_viewable.where.not(storage_size: nil).order(:storage_size).first
        record_status(online: false, message: 'No dataset available for download to perform test') unless identifier.present?
        resource = identifier.resources.where.not(download_uri: nil).order(:id).last

        client = Stash::Repo::HttpClient.new(cert_file: APP_CONFIG.ssl_cert_file).client
        resp = client.head(resource.download_uri, follow_redirect: true)
        online = resp.code == 200
        msg = "Merritt Download service is reporting an HTTP #{resp.code}!" unless online
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
