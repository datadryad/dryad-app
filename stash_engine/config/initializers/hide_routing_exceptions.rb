class ActionDispatch::DebugExceptions
  alias old_log_error log_error
  def log_error(env, wrapper)
    if wrapper.exception.is_a? ActionController::RoutingError # && ['stage', 'production'].include?(Rails.env)
      nil
    else
      old_log_error env, wrapper
    end
  end
end
