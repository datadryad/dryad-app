class PaymentDetailsPolicy < ApplicationPolicy
  def sponsor?
    @user.superuser?
  end

  def identifier?
    @user.system_user?
  end

  def edit?
    @user.superuser?
  end

  def update?
    @user.superuser?
  end

  def dashboard?
    @record.users.include?(@user) || @user.system_user?
  end
end
