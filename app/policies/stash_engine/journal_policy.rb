module StashEngine
  class JournalPolicy < ApplicationPolicy

    def index?
      @user.limited_curator? && !@user.tenant_limited?
    end

    def load?
      @user.superuser?
    end

  end
end
