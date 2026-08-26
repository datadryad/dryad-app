class HiddenPagesPolicy < ApplicationPolicy
  def index?
    @user.superuser?
  end

  def file_validation?
    @user.superuser?
  end
end
