module StashEngine
  class ResourcePolicy < ApplicationPolicy

    def index?
      @user.min_admin?
    end

    def create?
      @user.present?
    end

    def new?
      create?
    end

    def revise?
      @record.users.include?(@user)
    end

    def delete?
      @record.creator == @user || @record.submitter == @user
    end

    def curate?
      return @record.tenant_id == @user.tenant_id if @user.roles.tenant_roles.curator.present?

      @user.min_curator?
    end

    def curator_edit?
      (curate? &&
      (@record.current_resource_state&.resource_state == 'submitted')) ||
      (@record.current_resource_state&.resource_state == 'in_progress' && @record&.user_id == @user.id)
    end

    def flag?
      @user.system_user?
    end

    def change_status?
      @record.curatable? || @user.min_manager?
    end

    class VersionScope
      def initialize(user, scope)
        @user = user
        @scope = scope
      end

      def resolve
        if @user.nil?
          @scope.with_visibility(states: %w[published embargoed])
        elsif @user.min_app_admin?
          @scope.all
        else
          tenant_admin = (@user.tenant_id if @user.roles.tenant_roles.admin.present?)
          @scope.with_visibility(states: %w[published embargoed],
                                 tenant_id: tenant_admin,
                                 funder_ids: @user.funders.map(&:funder_id),
                                 journal_issns: @user.journals_as_admin.map(&:single_issn),
                                 user_id: @user.id)
        end
      end

      private

      attr_reader :user, :scope
    end
  end
end
