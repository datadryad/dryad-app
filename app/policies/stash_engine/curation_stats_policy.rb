module StashEngine
  class CurationStatsPolicy < ApplicationPolicy

    def index?
      @user.min_admin?
    end

  end
end
