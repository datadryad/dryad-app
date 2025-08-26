module StashEngine
  class SavedSearchPolicy < ApplicationPolicy

    def index?
      @user.present?
    end

    def create?
      index?
    end

    def edit?
      @user.id == @record.user_id
    end

    def update
      edit?
    end

    def destroy
      edit?
    end

  end
end
