module StashEngine
  class JournalPolicy < ApplicationPolicy

    def index?
      @user.system_user?
    end

    def popup?
      @user.superuser?
    end

  end
end
