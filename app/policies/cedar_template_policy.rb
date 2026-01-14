class CedarTemplatePolicy < ApplicationPolicy

  def index?
    @user.system_user?
  end

  def show?
    @user.system_user?
  end

  def create?
    @user.min_manager?
  end

  def new?
    create?
  end

  def update?
    @user.min_manager?
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

end
