module StashEngine
  class ProposedChangePolicy < ApplicationPolicy

    def index?
      @user.curator?
    end

    def update?
      @user.curator?
    end

    def edit?
      update?
    end

    def destroy?
      @user.curator?
    end

  end
end
