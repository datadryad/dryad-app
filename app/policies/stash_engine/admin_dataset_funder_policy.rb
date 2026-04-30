module StashEngine
  class AdminDatasetFunderPolicy < ApplicationPolicy
    def index?
      @user.min_admin?
    end

    class Scope
      def initialize(user, scope)
        @user = user
        @scope = scope
      end

      def resolve
        @user.tenant_limited? || @scope
      end

      private

      attr_reader :user, :scope
    end
  end
end
