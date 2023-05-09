module StashEngine
  class AdminDatasetFunderPolicy < ApplicationPolicy
    def index?
      user.admin?
    end

    class Scope
      def initialize(user, scope)
        @user = user
        @scope = scope
      end

      def resolve
        if @user.tenant_limited?
          @scope.add_where(arr: ['last_res.tenant_id = ?', @user.tenant_id])
        else
          @scope
        end
      end

      private

      attr_reader :user, :scope
    end
  end
end
