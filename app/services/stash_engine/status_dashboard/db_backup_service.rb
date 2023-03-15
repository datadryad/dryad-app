# frozen_string_literal: true

require 'httparty'

module StashEngine
  module StatusDashboard

    class DbBackupService < DependencyCheckerService

      BACKUP_DIR = '/dryad/apps/ui/shared/cron/backups'

      def ping_dependency
        super
        record_status(online: false, message: "No backup dir found at '#{BACKUP_DIR}'.") unless File.exist?(BACKUP_DIR) &&
                                                                                                File.directory?(BACKUP_DIR)
        return false unless File.exist?(BACKUP_DIR) && File.directory?(BACKUP_DIR)

        # Find the date of the most recent file modification
        last_run_date = 1.year.ago
        last_file = ''
        Dir.each_child(BACKUP_DIR) do |f|
          modified = File.mtime("#{BACKUP_DIR}/#{f}")
          if modified >= last_run_date
            last_run_date = modified
            last_file = f
          end
        end

        online = last_run_date >= (Time.now - 90.minutes)

        msg = "The database backup service last ran at '#{last_run_date}'. " unless online
        record_status(online: online, message: msg)
        online
      rescue StandardError => e
        record_status(online: false, message: e.to_s)
        false
      end

    end

  end
end
