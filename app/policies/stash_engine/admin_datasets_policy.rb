module StashEngine
  class AdminDatasetsPolicy
    attr_reader :user, :datasets

    def initialize(user, datasets)
      @user = user
      @datasets = datasets
    end

    class Scope
      def initialize(user, scope, params)
        @user = user
        @scope = scope
        @params = params
      end

      def resolve
        if @user.tenant_limited?
          @scope.where(**@params, tenant: @user.tenant)
        elsif @user.limited_curator?
          @scope.where(**@params)
        elsif @user.journals_as_admin.present?
          @scope.where(**@params, journals: @user.journals_as_admin.map(&:title))
        elsif @user.funders_as_admin.present?
          @scope.where(**@params, funders: @user.funders_as_admin.map(&:funder_id))
        else
          false
        end
      end

      private

      attr_reader :user, :scope
    end
  end
end
