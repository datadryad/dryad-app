class PaymentDetailsPolicy < ApplicationPolicy
  def sponsor?
    @user.superuser?
  end

  def identifier?
    @user.system_user?
  end

  def dashboard?
    @record.users.include?(@user) || @user.system_user?
  end
end
