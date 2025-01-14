module StashEngine
  class JournalPolicy < ApplicationPolicy

    def index?
      @user.system_user?
    end

    def popup?
      @user.system_admin?
    end

    def detail?
      @user && @user.system_user?
    end

    def create?
      @user.superuser?
    end

    def new?
      create?
    end

  end
end
