module StashEngine
  class AdminSearchPolicy < ApplicationPolicy

    def new_search?
      @user.min_admin?
    end

    def save_search?
      @user.id == @record.user_id
    end

  end
end
