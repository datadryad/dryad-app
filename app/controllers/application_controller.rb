class ApplicationController < ActionController::Base
  include Blacklight::Controller
  layout 'blacklight'

  protect_from_forgery with: :exception
end
