module StashEngine
  class UserPolicy < ApplicationPolicy
    def index?
      @user.system_user?
    end

    def merge_popup?
      merge?
    end

    def merge?
      @user.superuser?
    end

    def edit?
      @user.system_admin?
    end

    def update?
      edit?
    end

    def user_profile?
      @user.system_user?
    end
  end
end
