module StashEngine
  class ProposedChangePolicy < ApplicationPolicy

    def index?
      @user.limited_curator?
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
