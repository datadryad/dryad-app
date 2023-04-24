# frozen_string_literal: true

module StashEngine
  class ProposedChangePolicy
    attr_reader :user, :change

    def initialize(user, change)
      @user = user
      @change = change
    end

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
