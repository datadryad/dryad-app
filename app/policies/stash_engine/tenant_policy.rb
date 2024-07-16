module StashEngine
  class TenantPolicy < ApplicationPolicy
    def index?
      @user.present?
    end

    def admin?
      @user.system_user?
    end

    def popup?
      @user.system_admin?
    end

    class Scope
      def initialize(user, scope)
        @user = user
        @scope = scope
      end

      def resolve
        if @user.tenant_limited?
          @scope.enabled.joins(:tenant_ror_orgs).where(tenant_ror_orgs: { ror_id: user.tenant.ror_ids }).distinct
        elsif @user.system_user?
          @scope.all
        else
          []
        end
      end

      private

      attr_reader :user, :scope
    end
  end
end
