class ApplicationController < ActionController::Base

  before_action :set_paper_trail_whodunnit

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
end
