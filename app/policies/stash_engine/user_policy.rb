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

    def popup?
      edit?
    end

    def edit?
      @user.superuser?
    end

    def user_profile?
      @user.system_user?
    end

    def set_role?
      @user.superuser?
    end
  end
end
