module StashEngine
  class CurationStatsPolicy < ApplicationPolicy

    def index?
      @user.min_app_admin?
    end

  end
end
