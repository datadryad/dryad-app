class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception, prepend: true

  def process_action(*args)
    super

  # Show Bad Request Error for bad Content-Type or Accept headers
  rescue ActionDispatch::Http::MimeNegotiation::InvalidType => e
    render status: 400, plain: e.message
  end

end
