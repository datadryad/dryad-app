class HiddenPagesPolicy < ApplicationPolicy
  def index?
    @user.superuser?
  end

  def file_validation?
    @user.superuser?
  end

  def sponsor_payment_details?
    @user.superuser?
  end

  def identifier_payment_details?
    @user.superuser?
  end
end
