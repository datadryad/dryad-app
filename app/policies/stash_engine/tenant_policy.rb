module StashEngine
  class TenantPolicy < ApplicationPolicy
    def index?
      user.present?
    end

    class Scope
      def initialize(user, scope)
        @user = user
        @scope = scope
      end

      def resolve
        if @user.tenant_limited?
          @scope.all.select { |tenant| user.tenant.ror_ids.include?(tenant.ror_ids.first) }
        else
          @scope.all
        end
      end

      private

      attr_reader :user, :scope
    end
  end
end
