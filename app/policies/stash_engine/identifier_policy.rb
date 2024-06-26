module StashEngine
  class IdentifierPolicy < ApplicationPolicy

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

    class DashboardScope
      def initialize(user, scope)
        @user = user
        @scope = scope
      end

      def resolve
        @scope
          .joins(latest_resource: :last_curation_activity)
          .where(latest_resource: { user_id: @user&.id })
          .select("stash_engine_identifiers.*,
            CASE
              WHEN status in ('in_progress', 'action_required') THEN 0
              WHEN status='peer_review' THEN 1
              WHEN status in ('submitted', 'curation', 'processing') THEN 2
              WHEN status='withdrawn' THEN 4
              ELSE 3
            END as sort_order")
          .order('sort_order ASC')
          .merge(CurationActivity.order(updated_at: :desc))
      end

      private

      attr_reader :user, :scope
    end

  end
end
