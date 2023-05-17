module StashEngine
  class CurationActivityPolicy < ApplicationPolicy

    def index?
      @user.limited_curator?
    end

    def curation_note?
      @user.limited_curator?
    end

  end
end