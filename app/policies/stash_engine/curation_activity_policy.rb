module StashEngine
  class CurationActivityPolicy < ApplicationPolicy

    def index?
      @user.limited_curator?
    end

    def curation_note?
      @user.admin?
    end

    def file_note?
      @user.limited_curator? ||
      @user.id = @resource.user_id
    end

  end
end
