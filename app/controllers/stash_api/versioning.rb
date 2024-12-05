module StashApi
  module Versioning
    extend ActiveSupport::Concern

    private

    def set_response_version_header
      response.headers['X-API-Version'] = api_version
      return if api_version == current_version

      response.headers['X-API-Deprecation'] = 'true'
    end

    def check_requested_version
      return if !requested_version || requested_version == current_version

      render json: { error: "Unsupported API version: #{requested_version}, latest version is: #{current_version}" }, status: 400
    end

    def current_version
      '2.1.0'
    end

    def api_version
      return requested_version if requested_version

      request.path.include?('/api/v2') ? '2.1.0' : '1.0.0'
    end

    def requested_version
      @requested_version ||= request.headers['X-API-Version']
    end
  end
end
