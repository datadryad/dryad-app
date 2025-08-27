module StashEngine
  class UserPolicy < ApplicationPolicy
    def index?
      @user.system_user?
    end

    def merge_popup?
      merge?
    end

    def merge?
      @user.min_manager?
    end

    def edit?
      @user.min_manager?
    end

    def update?
      edit?
    end

    def api_application?
      edit?
    end

    def user_profile?
      @user.system_user?
    end
  end
end
