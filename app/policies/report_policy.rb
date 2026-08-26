class ReportPolicy < ApplicationPolicy

  def index?
    @user.min_curator?
  end

end
