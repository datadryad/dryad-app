module StashEngine
  class AdminDatasetsPolicy < ApplicationPolicy

    def index?
      @user.min_admin?
    end

    def activity_log?
      index?
    end

    def stats_popup?
      index?
    end

    def note_popup?
      index?
    end

    def data_popup?
      @user.min_app_admin?
    end

    def curation_actions?
      @user.min_curator?
    end

    def create_salesforce_case?
      @user.min_app_admin?
    end

    def waiver_add?
      @user.superuser?
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
        elsif @user.min_app_admin?
          @scope.where(**@params)
        elsif @user.journals_as_admin.present?
          @scope.where(**@params, journals: @user.journals_as_admin.map(&:title))
        elsif @user.funders.present?
          @scope.where(**@params, funders: @user.funders.map(&:ror_id))
        else
          false
        end
      end

      private

      attr_reader :user, :scope
    end
  end
end
