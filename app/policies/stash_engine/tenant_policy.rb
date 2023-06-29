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
          @scope.all.select { |tenant| tenant.tenant_id == @user.tenant_id || tenant.tenant_id.start_with?("#{@user.tenant_id}-") }
        else
          @scope.all
        end
      end

      private

      attr_reader :user, :scope
    end
  end
end
