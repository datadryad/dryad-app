class PaymentDetailsPolicy < ApplicationPolicy
  def sponsor?
    @user.system_user?
  end

  def identifier?
    @user.system_user?
  end
end
