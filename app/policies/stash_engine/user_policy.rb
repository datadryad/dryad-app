module StashEngine
  class UserPolicy < ApplicationPolicy
    def index?
      @user.min_app_admin?
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
      @user.min_app_admin?
    end

    def set_role?
      @user.superuser?
    end
  end
end
