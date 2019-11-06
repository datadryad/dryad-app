# frozen_string_literal: true

require 'httparty'

module StashEngine
  module StatusDashboard

    class SolrService < DependencyCheckerService

      def ping_dependency
        super
        # Check the status of the solr port
        target = ENV['SOLR_URL'] || StashEngine::Engine.routes.url_helpers.search_url
        resp = HTTParty.get(target)
        online = resp.code == 200
        msg = resp.body unless online
        record_status(online: online, message: msg)
        online
      rescue HTTParty::Error, SocketError => e
        record_status(online: false, message: e.to_s)
        false
      end

    end

  end
end
