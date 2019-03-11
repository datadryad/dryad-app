require 'stash/streamer'
require 'httpclient'
require 'uri'

module StashEngine
  class ApplicationController < ::ApplicationController

    include SharedController
    include SharedSecurityController

    prepend_view_path("#{Rails.application.root}/app/views")

    # the sort_column should be set by sortable_table gem and sorts manually by sort column object from sortable_table
    def manual_sort!(array, sort_column)
      c = sort_column.column
      if sort_column && sort_column.direction == 'desc'
        array.sort! { |x, y| y.send(c) <=> x.send(c) }
      else
        array.sort! { |x, y| x.send(c) <=> y.send(c) }
      end
    end

    # returns the :return_to_path set in the session or else goes back to the path supplied
    def return_to_path_or(default_path)
      return session.delete(:return_to_path) if session[:return_to_path]
      default_path
    end

    def set_return_to_path_from_referrer
      session[:return_to_path] = request.env['HTTP_REFERER'] if request.env['HTTP_REFERER'].present? &&
          request.env['HTTP_REFERER'] != request.env['REQUEST_URI']
    end

    private

    def display_authorization_failure
      Rails.logger.warn("Resource #{resource ? resource.id : 'nil'}: user ID is #{resource.user_id || 'nil'} but " \
                        "current user is #{current_user.id || 'nil'}")
      flash[:alert] = 'You do not have permission to modify this dataset.'
      redirect_to stash_engine.dashboard_path
    end

    def redirect_url_for(original_url, host, port)
      uri = URI(original_url)
      uri.host = host
      uri.port = port if port
      uri.to_s
    end

  end
end
