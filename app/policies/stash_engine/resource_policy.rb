module StashEngine
  class ResourcePolicy < ApplicationPolicy

    def create?
      @user.present?
    end

    def new?
      create?
    end

    class Scope
      def initialize(user, scope)
        @user = user
        @scope = scope
      end

      def resolve
        @scope.where(user_id: @user.id)
      end

      private

      attr_reader :user, :scope
    end
  end
end
