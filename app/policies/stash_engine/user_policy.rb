module StashEngine
  class UserPolicy < ApplicationPolicy
    def index?
      @user.superuser?
    end

    def load?
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
