module StashEngine
  class ProposedChangePolicy < ApplicationPolicy

    def index?
      @user.min_curator?
    end

    def log?
      index?
    end

    def update?
      @user.min_curator?
    end

    def edit?
      update?
    end

    def destroy?
      @user.min_curator?
    end

  end
end
