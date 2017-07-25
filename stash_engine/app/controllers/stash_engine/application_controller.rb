require 'stash/streamer'
require 'httpclient'
require 'uri'

module StashEngine
  class ApplicationController < ::ApplicationController

    helper_method :owner?, :admin?

    include SharedController

    prepend_view_path("#{Rails.application.root}/app/views")

    def force_to_domain
      return if session[:test_domain]

      host, port = tenant_host_and_port(current_tenant_display)
      return if host_and_port_match?(request, host, port)

      redirect_to(redirect_url_for(request.original_url, host, port))
    end

    # the sort_column should be set by sortable_table gem and sorts manually by sort column object from sortable_table
    def manual_sort!(array, sort_column)
      c = sort_column.column
      if sort_column && sort_column.direction == 'desc'
        array.sort! { |x, y| y.send(c) <=> x.send(c) }
      else
        array.sort! { |x, y| x.send(c) <=> y.send(c) }
      end
    end

    def require_modify_permission
      return if owner? || current_user.superuser? || admin?
      display_authorization_failure
    end

    private

    # these owner/admin need to be in controller since they address the current_user from session, not easily available from model
    def owner?
      resource.user_id == current_user.id
    end

    def admin?
      (current_user.tenant_id == resource.user.tenant_id && current_user.role == 'admin')
    end

    def display_authorization_failure
      Rails.logger.warn("Resource #{resource ? resource.id : 'nil'}: user ID is #{resource.user_id || 'nil'} but " \
                        "current user is #{current_user.id || 'nil'}")
      flash[:alert] = 'You do not have permission to modify this dataset.'
      redirect_to stash_engine.dashboard_path
    end

    def host_and_port_match?(request, host, port)
      request.host == host && (port.nil? || request.port == port.to_i)
    end

    def tenant_host_and_port(tenant)
      full_domain = tenant.full_domain
      host, port = full_domain.split(':')
      [host, port]
    end

    def redirect_url_for(original_url, host, port)
      uri = URI(original_url)
      uri.host = host
      uri.port = port if port
      uri.to_s
    end

  end
end
