module StashEngine
  class TenantPolicy < ApplicationPolicy
    def index?
      @user.present?
    end

    class Scope
      def initialize(user, scope)
        @user = user
        @scope = scope
      end

      def resolve
        if @user.tenant_limited?
          @scope.enabled.joins(:tenant_ror_orgs).where(tenant_ror_orgs: { ror_id: user.tenant.ror_ids })
        else
          @scope.all
        end
      end

      private

      attr_reader :user, :scope
    end
  end
end
