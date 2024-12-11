module StashEngine
  class SavedSearchPolicy < ApplicationPolicy

    def index?
      @user.id == @record.user_id
    end

    def create?
      @user.present?
    end

    def edit?
      index?
    end

    def update
      index?
    end

    def destroy
      index?
    end

  end
end
