module StashEngine
  class JournalsController < ApplicationController

    helper SortableTableHelper

    def index
      params.permit(:q)
      params[:sort] = 'title' if params[:sort].blank?
      @metadata_journals = Journal.joins(:manuscripts).where("stash_engine_manuscripts.created_at > '#{1.year.ago.iso8601}'").distinct.map(&:id)
      @api_journals = StashEngine::User.joins('inner join oauth_applications on owner_id = stash_engine_users.id')
        .joins(
          "inner join stash_engine_roles on stash_engine_users.id = stash_engine_roles.user_id
          and role_object_type in ('StashEngine::Journal', 'StashEngine::JournalOrganization')"
        ).distinct.map(&:journals_as_admin).flatten.uniq.map(&:id)
      sponsoring_journals = Journal.where.not(payment_plan_type: [nil, '']).map(&:id)
      display_journals = @metadata_journals | sponsoring_journals | @api_journals

      ord = helpers.sortable_table_order(whitelist: %w[title issn allow_blackout payment_plan_type name parent_org_id sponsor_id default_to_ppr])
      @journals = Journal.left_outer_joins(:sponsor).where(id: display_journals).order(ord, title: :asc)
        .preload(:sponsor).preload(:issns)

      respond_to do |format|
        format.html
        format.csv do
          headers['Content-Disposition'] = "attachment; filename=journals_#{Time.new.strftime('%F')}.csv"
        end
      end
    end
  end
end
