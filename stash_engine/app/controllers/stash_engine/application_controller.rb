require 'stash/streamer'
require 'httpclient'
require 'uri'

module StashEngine
  class ApplicationController < ::ApplicationController

    include SharedController

    prepend_view_path("#{Rails.application.root}/app/views")

    def force_to_domain
      return if session[:test_domain] || request.host == current_tenant_display.full_domain
      uri = URI(request.original_url)
      uri.host = current_tenant_display.full_domain
      redirect_to(uri.to_s)
    end

  end
end
