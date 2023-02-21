# frozen_string_literal: true

require 'httparty'

module StashEngine
  module StatusDashboard

    class WordpressService < DependencyCheckerService

      def ping_dependency
        super
        resp = HTTParty.get('https://blog.datadryad.org/')
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
