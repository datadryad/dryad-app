module StashEngine
  class JournalOrganizationPolicy < ApplicationPolicy

    def index?
      @user.min_app_admin?
    end

    def popup?
      @user.superuser?
    end

  end
end
