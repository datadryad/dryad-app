module StashEngine
  class IdentifierPolicy < ApplicationPolicy

    class Scope
      def initialize(user, scope)
        @user = user
        @scope = scope
      end

      def resolve
        @scope
          .joins(latest_resource: :last_curation_activity)
          .where(latest_resource: { user_id: @user.id })
          .select("stash_engine_identifiers.*,
            CASE
              WHEN status in ('in_progress', 'action_required') THEN 0
              WHEN status='peer_review' THEN 1
              WHEN status in ('submitted', 'curation', 'processing') THEN 2
              WHEN status='withdrawn' THEN 4
              ELSE 3
            END as sort_order")
          .order('sort_order ASC')
          .order('updated_at DESC')
      end

      private

      attr_reader :user, :scope
    end

  end
end
