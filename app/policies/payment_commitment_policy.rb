class PaymentCommitmentPolicy < ApplicationPolicy

  def new?
    create?
  end

  def create?
    @user.superuser?
  end

  def edit?
    create?
  end

  def update?
    create?
  end

  def index?
    create?
  end
end
