module StashEngine
  class PublicationUpdaterController < ApplicationController
    helper SortableTableHelper
    before_action :require_user_login
    before_action :setup_paging, only: [:index]
    before_action :setup_filter, only: [:index]
    before_action :check_status, only: %i[update destroy]

    CONCAT_FOR_SEARCH = <<~SQL.freeze
       JOIN
        (SELECT sepc2.id,
         CONCAT_WS(' ',
           sepc2.publication_doi,
           sepc2.publication_issn,
           sepc2.publication_name,
           sepc2.title,
           sei2.identifier,
           ser2.title) AS big_text
       FROM `stash_engine_proposed_changes` sepc2
         INNER JOIN `stash_engine_identifiers` sei2
           ON sei2.id = sepc2.identifier_id
         INNER JOIN `stash_engine_resources` ser2
           ON ser2.`id` = sei2.`latest_resource_id`
      ) search_table
       ON search_table.id = stash_engine_proposed_changes.id
    SQL

    # the admin datasets main page showing users and stats, but slightly different in scope for curators vs tenant admins
    def index
      proposed_changes = authorize StashEngine::ProposedChange.unmatched
        .preload(:latest_resource)
        .joins(latest_resource: [:last_curation_activity])
        .where("stash_engine_curation_activities.status NOT IN('in_progress', 'processing', 'embargoed')")
        .where("stash_engine_identifiers.pub_state != 'withdrawn'")
        .select('stash_engine_proposed_changes.*')

      params[:match_type] = 'articles' if params[:match_type].blank?

      proposed_changes = add_param_filters(proposed_changes)

      params[:sort] = 'score' if params[:sort].blank?
      params[:direction] = 'desc' if params[:direction].blank?

      ord = helpers.sortable_table_order(whitelist:
         %w[stash_engine_proposed_changes.title publication_name publication_issn publication_doi
            stash_engine_proposed_changes.publication_date authors score])

      if request.format.to_s == 'text/csv' # we want all the results to put in csv
        @page = 1
        @page_size = 1_000_000
      end

      @proposed_changes = proposed_changes.order(ord).page(@page).per(@page_size)
      return unless @proposed_changes.present?

      respond_to do |format|
        format.html
        format.csv do
          headers['Content-Disposition'] = "attachment; filename=#{Time.new.strftime('%F')}_pub_updater_report.csv"
        end
      end
    end

    def update
      respond_to do |format|
        @proposed_change.approve!(current_user: current_user, approve_type: params['stash_engine_proposed_change']['related_type'])
        @proposed_change.reload
        format.js
      end
    end

    def destroy
      respond_to do |format|
        @proposed_change.reject!(current_user: current_user)
        @proposed_change.reload
        format.js
      end
    end

    private

    def setup_paging
      @page = params[:page] || '1'
      @page_size = if params[:page_size].blank? || params[:page_size].to_i == 0
                     10
                   else
                     params[:page_size].to_i
                   end
    end

    def setup_filter
      @statuses = [OpenStruct.new(value: '', label: '*Select status*')]
      excluded = StashEngine::CurationActivity.statuses.except(:in_progress, :processing, :embargoed, :withdrawn)
      @statuses << excluded.keys.map do |s|
        OpenStruct.new(value: s, label: StashEngine::CurationActivity.readable_status(s))
      end
      @statuses.flatten!
    end

    def check_status
      @proposed_change = authorize StashEngine::ProposedChange.find(params[:id])
      @resource = @proposed_change&.latest_resource if @proposed_change.present?
      refresh_error if @proposed_change.approved? || @proposed_change.rejected?
    end

    def add_param_filters(proposed_changes)
      if params[:list_search].present?
        proposed_changes = proposed_changes.joins(CONCAT_FOR_SEARCH)

        keys = params[:list_search].split(/\s+/).map(&:strip)
        proposed_changes = proposed_changes.where((['search_table.big_text LIKE ?'] * keys.size).join(' AND '), *keys.map { |key| "%#{key}%" })
      end

      if params[:status].present?
        proposed_changes = proposed_changes.joins(
          'JOIN stash_engine_curation_activities sa ON sa.id = stash_engine_resources.last_curation_activity_id'
        ).where('sa.status' => params[:status])
      end

      if params[:match_type].present?
        proposed_changes = proposed_changes.where(
          "stash_engine_proposed_changes.publication_issn is #{params[:match_type] == 'preprints' ? 'null' : 'not null'}"
        )
      end

      proposed_changes
    end

    def refresh_error
      @error_message = <<-HTML.chomp.html_safe
        <p>This proposed change has already been processed.</p>
        <p>Close this dialog to refresh the publication updater results.</p>
      HTML
      render :refresh_error
    end

  end
end
