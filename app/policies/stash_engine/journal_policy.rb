module StashEngine
  class JournalPolicy < ApplicationPolicy

    def index?
      @user.system_user?
    end

    def edit?
      @user.min_manager?
    end

    def update?
      edit?
    end

    def detail?
      @user && @user.system_user?
    end

    def create?
      @user.min_manager?
    end

    def new?
      create?
    end

  end
end
