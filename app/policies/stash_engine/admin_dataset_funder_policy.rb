module StashEngine
  class AdminDatasetFunderPolicy < ApplicationPolicy
    def index?
      @user.admin?
    end

    class Scope
      def initialize(user, scope)
        @user = user
        @scope = scope
      end

      def resolve
        if @user.tenant_limited?
          @user.tenant_id
        elsif @scope.present?
          @scope
        end
      end

      private

      attr_reader :user, :scope
    end
  end
end
