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
        if @user.tenant_limited?
          true
        else
          @scope
        end
      end

      private

      attr_reader :user, :scope
    end
  end
end
