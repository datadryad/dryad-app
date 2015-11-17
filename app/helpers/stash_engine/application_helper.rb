module StashEngine
  module ApplicationHelper
    def title(resource)
      if resource.nil?
        'unknown'
      else
        @titles.where(resource_id: resource.id).pluck(:title).join(' ')
      end
    end

    # displays log in/out based on session state, temorary for now
    # :nocov:
    def log_in_out
      if session[:email].blank?
        link_to 'log in', tenants_path
      else
        link_to 'log out', sessions_destroy_path
      end
    end
    # :nocov:
  end
end
