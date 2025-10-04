class SidekiqAccessConstraint
  def matches?(request)
    user_id = request.session[:user_id]
    user = StashEngine::User.find_by(id: user_id)
    user&.superuser?
  end
end
