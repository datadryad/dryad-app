module StashEngine
  class JournalOrganizationPolicy < ApplicationPolicy

    def index?
      @user.system_user?
    end

    def edit?
      @user.system_admin?
    end

    def update?
      edit?
    end

    def create?
      @user.superuser?
    end

    def new?
      create?
    end

  end
end
