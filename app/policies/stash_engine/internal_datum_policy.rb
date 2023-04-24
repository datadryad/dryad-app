# frozen_string_literal: true

module StashEngine
  class InternalDatumPolicy
    attr_reader :user, :internal_data

    def initialize(user, internal_data)
      @user = user
      @internal_data = internal_data
    end

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
