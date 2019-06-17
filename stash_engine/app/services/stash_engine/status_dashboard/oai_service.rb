# frozen_string_literal: true

require 'httparty'

module StashEngine
  module StatusDashboard

    class OaiService < DependencyCheckerService

      def ping_dependency
        super
        timeframe = (Time.now - 5.minutes).utc.strftime('%y-%m-%dT%H:%M:%SZ')
        env = Rails.env.production? ? 'prd' : 'stg'
        base_url = "http://uc3-mrtoai-#{env}.cdlib.org:37001/mrtoai/oai/v2"
        target = "#{base_url}?verb=ListRecords&metadataPrefix=dcs3.1&from=#{timeframe}"

        resp = HTTParty.get(target)
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
