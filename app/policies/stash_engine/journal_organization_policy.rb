module StashEngine
  class JournalOrganizationPolicy < ApplicationPolicy

    def index?
      @user.system_user?
    end

    def popup?
      @user.system_admin?
    end

    def create?
      @user.superuser?
    end

    def new?
      create?
    end

  end
end
