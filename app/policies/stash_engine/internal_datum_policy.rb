module StashEngine
  class InternalDatumPolicy < ApplicationPolicy

    def index?
      @user.min_app_admin?
    end

    def create?
      @user.min_app_admin?
    end

    def new?
      create?
    end

    def update?
      @user.min_app_admin?
    end

    def edit?
      update?
    end

    def destroy?
      @user.min_app_admin?
    end

  end
end
