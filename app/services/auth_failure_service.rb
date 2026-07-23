class AuthFailureService

  def initialize(request, current_user, params)
    @current_user = current_user
    @request = request
    @params = params
  end

  def unauthorized
    create('unauthorized')
  end

  def api_unauthorized
    create('api_unauthorized')
  end

  def api_expired_token
    create('api_unauthorized')
  end

  def create(error_type)
    raise ArgumentError, "Invalid error_type: #{error_type}" unless error_type.to_s.in?(AuthFailure.error_types.keys)

    AuthFailure.create!(
      ip: @request.remote_ip,
      url: @request.fullpath,
      params: @params,
      user_id: @current_user&.id,
      user_agent: @request.user_agent,
      error_type: error_type
    )
  end
end
