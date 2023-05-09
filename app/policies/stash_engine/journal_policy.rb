module StashEngine
  class JournalPolicy < ApplicationPolicy

    def index?
      @user.limited_curator? && !@user.tenant_limited?
    end

  end
end
