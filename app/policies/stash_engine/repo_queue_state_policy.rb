module StashEngine
  class RepoQueueStatePolicy < ApplicationPolicy

    def index?
      @user.min_manager?
    end

    def refresh_table?
      @user.min_manager?
    end

    def graceful_start?
      @user.superuser?
    end

  end
end
