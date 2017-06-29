require 'stash/streamer'
require 'httpclient'
require 'uri'

module StashEngine
  class ApplicationController < ::ApplicationController

    include SharedController

    prepend_view_path("#{Rails.application.root}/app/views")

    def force_to_domain
      return if session[:test_domain]

      host, port = tenant_host_and_port(current_tenant_display)
      return if host_and_port_match?(request, host, port)

      redirect_to(redirect_url_for(request.original_url, host, port))
    end

    private

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
