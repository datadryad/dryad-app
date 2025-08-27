module StashEngine
  class IdentifierPolicy < ApplicationPolicy

    def destroy?
      @user.min_manager? &&
        @record.resources.count == 1 &&
        @record.resources.first.curation_activities.pluck(:status).uniq == ['in_progress']
    end

    def reset_payments?
      @user.min_manager? &&
        @record.payments.count == 1 &&
        @record.payments.first.pay_with_invoice
    end

    class Scope
      def initialize(user, scope)
        @user = user
        @scope = scope
      end

      def resolve
        if !@user || @user.nil?
          @scope.publicly_viewable
        elsif @user.min_app_admin?
          @scope.all
        else
          tenant_admin = (@user.tenant_id if @user.roles.tenant_roles.admin.present?)
          @scope.with_visibility(states: %w[published embargoed],
                                 tenant_id: tenant_admin,
                                 journal_issns: @user.journals_as_admin.map(&:single_issn),
                                 funder_ids: @user.funders.map(&:funder_id),
                                 user_id: @user.id)
        end
      end

      private

      attr_reader :user, :scope
    end

  end
end
