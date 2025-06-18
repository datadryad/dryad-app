class SidekiqAccessConstraint
  def matches?(request)
    user_id = request.session[:user_id] # Adjust based on your auth system
    user = StashEngine::User.find_by(id: user_id)
    user&.superuser?
    true
  end
end
