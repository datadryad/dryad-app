class FeeRecordPolicy < ApplicationPolicy
  def show?
    @record.resource.admin_for_this_item?(user: @user) ||
    @record.resource.submitter == @user
  end
end
