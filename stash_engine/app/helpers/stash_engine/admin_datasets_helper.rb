module StashEngine
  module AdminDatasetsHelper

    def institution_select
      StashEngine::Tenant.all.map { |item| [item.short_name, item.tenant_id] }
    end

    def status_select(statuses = [])
      statuses = StashEngine::CurationActivity.statuses if statuses.empty?
      statuses.map do |status|
        [StashEngine::CurationActivity.readable_status(status), status]
      end
    end

    def filter_status_select(current_status)
      statuses = StashEngine::CurationActivity.statuses

      case current_status
      when 'submitted', 'peer_review'
        statuses = statuses.select { |s| %w[curation withdrawn].include?(s) }
      when 'withdrawn'
        statuses = statuses.select { |s| %w[curation].include?(s) }
      else
        unavailable = %w[in_progress submitted peer_review]
        unavailable << current_status
        statuses = statuses.reject { |s| unavailable.include?(s) }
      end

      status_select(statuses)
    end

  end
end
