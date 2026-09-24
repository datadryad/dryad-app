class ApplicationController < ActionController::Base

  include Pundit::Authorization

  before_action :add_security_headers
  before_action :set_paper_trail_whodunnit
  before_action :protect_from_host_header_attack

  def process_action(*args)
    super

    # Show Bad Request Error for bad Content-Type/Accept headers, Invalid URI
  rescue ActionDispatch::Http::MimeNegotiation::InvalidType, URI::InvalidURIError => e
    render status: 400, plain: e.message
  end

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception, prepend: true

  private

  def allow_iframe_requests
    response.headers.delete('X-Frame-Options') # remove default
    response.headers['X-Frame-Options'] = 'ALLOWALL' # or 'SAMEORIGIN'
  end

  def add_security_headers
    response.headers['Cache-Control'] = 'no-cache, no-store'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = 'Mon, 01 Jan 1990 00:00:00 GMT'
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    response.headers['Referrer-Policy'] = 'same-origin'
    response.headers['X-Frame-Options'] = 'SAMEORIGIN'
    response.headers['Strict-Transport-Security'] = 'max-age=63072000; includeSubDomains; preload'

    response.headers.delete('Server')
  end

  def protect_from_host_header_attack
    return if controller_name == 'help'
    return if request.host == Rails.application.default_url_options[:host]

    log_auth_failure
    render plain: 'Forbidden', status: 403
  end

  def log_auth_failure(type: :unauthorized)
    return if controller_name == 'csp_violation_reports'

    AuthFailureService.new(request, current_user, params).create(type)
  end
end
