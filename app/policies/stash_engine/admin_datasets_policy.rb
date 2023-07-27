module StashEngine
  class AdminDatasetsPolicy < ApplicationPolicy

    def index?
      @user.admin?
    end

    def activity_log?
      index?
    end

    def note_popup?
      index?
    end

    def data_popup?
      @user.limited_curator?
    end

    def curation_activity_change?
      @user.curator?
    end

    def curation_activity_popup?
      curation_activity_change?
    end

    def current_editor_change?
      @user.curator?
    end

    def current_editor_popup?
      current_editor_change?
    end

    def create_salesforce_case?
      @user.limited_curator?
    end

    def waiver_add?
      @user.superuser?
    end

    def waiver_popup?
      waiver_add?
    end

    def stats_popup?
      index?
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
