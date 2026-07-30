class ResearchIntegrityCasePolicy < ApplicationPolicy

  def index?
    @user.system_user?
  end

  def history?
    @user.min_manager?
  end

  def update?
    @user.min_manager?
  end

  def edit?
    update?
  end

end
