module StashEngine
  class InternalDatumPolicy < ApplicationPolicy

    def index?
      @user.limited_curator?
    end

    def create?
      @user.limited_curator?
    end

    def new?
      create?
    end

    def update?
      @user.limited_curator?
    end

    def edit?
      update?
    end

    def destroy?
      @user.limited_curator?
    end

  end
end
