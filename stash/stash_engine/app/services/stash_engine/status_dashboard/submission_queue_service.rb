module StashEngine
  module StatusDashboard

    class SubmissionQueueService < DependencyCheckerService

      def ping_dependency
        super

        online = true
        held_resources = RepoQueueState.latest_per_resource.where(state: 'rejected_shutting_down').order(:created_at)
        if held_resources.present? && too_old?(held_resources.first)
          online = false
          msg = "Submission processing has been shut down since #{held_resources.first.created_at}, and datasets are still waiting."
        end
        record_status(online: online, message: msg)
        online
      rescue StandardError => e
        record_status(online: false, message: e.to_s)
        false
      end

      def too_old?(res_state)
        res_state.created_at < 4.hours.ago
      end
    end
  end
end
