module StashEngine
  class JournalOrganizationPolicy < ApplicationPolicy

    def index?
      @user.system_user?
    end

    def popup?
      @user.superuser?
    end

  end
end
