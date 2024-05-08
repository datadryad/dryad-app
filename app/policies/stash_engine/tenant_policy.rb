module StashEngine
  class TenantPolicy < ApplicationPolicy
    def index?
      @user.present?
    end

    def admin?
      @user.min_app_admin?
    end

    def popup?
      @user.superuser?
    end

    class Scope
      def initialize(user, scope)
        @user = user
        @scope = scope
      end

      def resolve
        if @user.tenant_limited?
          @scope.enabled.joins(:tenant_ror_orgs).where(tenant_ror_orgs: { ror_id: user.tenant.ror_ids }).distinct
        else
          @scope.all
        end
      end

      private

      attr_reader :user, :scope
    end
  end
end
