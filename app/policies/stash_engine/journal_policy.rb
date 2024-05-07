module StashEngine
  class JournalPolicy < ApplicationPolicy

    def index?
      @user.min_app_admin? && !@user.tenant_limited?
    end

  end
end
