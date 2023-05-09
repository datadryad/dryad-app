module StashEngine
  class UserPolicy < ApplicationPolicy
    def index?
      @user.superuser?
    end

    def load_user?
      @user.superuser?
    end

    def merge_popup?
      @user.superuser?
    end

    def merge?
      @user.superuser?
    end
  end
end
