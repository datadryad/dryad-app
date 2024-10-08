module StashEngine
  class CurationActivityPolicy < ApplicationPolicy

    def index?
      @user.min_app_admin?
    end

    def curation_note?
      @user.min_admin?
    end

    def file_note?
      @user.min_app_admin? ||
      @resource.users.include?(@user)
    end

  end
end
