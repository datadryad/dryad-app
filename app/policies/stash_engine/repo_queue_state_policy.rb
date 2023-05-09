module StashEngine
  class RepoQueueStatePolicy < ApplicationPolicy

    def index?
      @user.superuser?
    end

    def refresh_table?
      @user.superuser?
    end

    def graceful_start?
      @user.superuser?
    end

  end
end
