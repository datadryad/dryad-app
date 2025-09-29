module StashEngine
  module DashboardHelper

    def dashboard_heading(order)
      case order
      when 0
        'Needs attention'
      when 1
        'In progress with another user'
      when 2
        'Kept private'
      when 3
        'Submitted to Dryad'
      when 4
        'Complete'
      when 5
        'Withdrawn'
      end
    end

    def dashboard_id(order)
      case order
      when 0
        'user_in-progress'
      when 1
        'user_other-editor'
      when 2
        'user_private'
      when 3
        'user_processing'
      when 4
        'user_complete'
      when 5
        'user_withdrawn'
      end
    end

    def dashboard_class(order)
      case order
      when 0
        'error-status'
      when 3
        'info-status'
      when 4
        'success-status'
      when 5
        'disabled-status'
      else
        'warning-status'
      end
    end

    def delete_confirm(dataset)
      str = 'Are you sure you want to remove this dataset'
      if dataset.stash_version&.version&. > 1
        str += ' version?'
        str += ' The published version will still be available.' if dataset.identifier.pub_state == 'published'
      else
        str += '?'
      end
      str
    end
  end
end
