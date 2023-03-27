class ApplicationController < ActionController::Base
  def process_action(*args)
    super

    # Show Bad Request Error for bad Content-Type/Accept headers, Invalid URI
  rescue ActionDispatch::Http::MimeNegotiation::InvalidType, URI::InvalidURIError => e
    render status: 400, plain: e.message
  end

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception, prepend: true

end
