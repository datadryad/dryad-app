module StashEngine
  class CurationStatsPolicy < ApplicationPolicy

    def index?
      @user.admin?
    end

  end
end
