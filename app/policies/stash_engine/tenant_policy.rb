module StashEngine
  class TenantPolicy < ApplicationPolicy
    def index?
      @user.present?
    end

    def admin?
      @user.system_user?
    end

    def edit?
      @user.min_manager?
    end

    def update?
      edit?
    end

    def create?
      @user.min_manager?
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
        if @user.tenant_limited?
          if user.tenant.ror_ids.length == 1
            [user.tenant]
          else
            @scope.enabled.joins(:tenant_ror_orgs).where(tenant_ror_orgs: { ror_id: user.tenant.ror_ids }).distinct
          end
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
