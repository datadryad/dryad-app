module StashEngine
  class ResourcePublicationPolicy < ApplicationPolicy

    def update?
      @user.min_app_admin?
    end

    def edit?
      update?
    end

  end
end
