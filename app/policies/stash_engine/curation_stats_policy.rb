module StashEngine
  class CurationStatsPolicy < ApplicationPolicy

    def index?
      @user.min_app_admin?
    end

    def charts?
      @user.min_app_admin?
    end

    def update_charts?
      charts?
    end

  end
end
