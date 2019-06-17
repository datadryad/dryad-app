# frozen_string_literal: true

require 'httparty'

module StashEngine
  module StatusDashboard

    class NotifierService < DependencyCheckerService

      def ping_dependency
        super
        pid = File.expand_path(File.join(Rails.root, '..', 'stash', 'stash-notifier', 'state', "#{Rails.env}.pid"))
        online = File.exist?(pid)
        msg = "No pid file found for the stash-notifier at #{pid}!" unless online
        record_status(online: online, message: msg)
        online
      rescue StandardError => e
        record_status(online: false, message: e.to_s)
        false
      end

    end

  end
end
