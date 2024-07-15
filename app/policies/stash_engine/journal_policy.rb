module StashEngine
  class JournalPolicy < ApplicationPolicy

    def index?
      @user.system_user?
    end

    def popup?
      @user.system_admin?
    end

  end
end
