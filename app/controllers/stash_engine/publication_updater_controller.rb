module StashEngine
  class PublicationUpdaterController < ApplicationController
    helper SortableTableHelper
    before_action :require_user_login
    before_action :setup_paging, only: [:index]

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

    # rubocop:disable Metrics/AbcSize
    # the admin datasets main page showing users and stats, but slightly different in scope for curators vs tenant admins
    def index
      proposed_changes = authorize StashEngine::ProposedChange # .includes(identifier: :latest_resource)
        .joins(identifier: :latest_resource).where(approved: false, rejected: false).select('stash_engine_proposed_changes.*')

      if params[:list_search].present?
        proposed_changes = proposed_changes.joins(CONCAT_FOR_SEARCH)

        keys = params[:list_search].split(/\s+/).map(&:strip)
        proposed_changes = proposed_changes.where((['search_table.big_text LIKE ?'] * keys.size).join(' AND '), *keys.map { |key| "%#{key}%" })
      end

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

      @resources = StashEngine::Resource.latest_per_dataset.where(identifier_id: @proposed_changes&.map(&:identifier_id))

      respond_to do |format|
        format.html
        format.csv do
          headers['Content-Disposition'] = "attachment; filename=#{Time.new.strftime('%F')}_pub_updater_report.csv"
        end
      end
    end
    # rubocop:enable Metrics/AbcSize

    def update
      respond_to do |format|
        @proposed_change = authorize StashEngine::ProposedChange.find(params[:id])
        @resource = @proposed_change.identifier&.latest_resource if @proposed_change.present?
        @proposed_change.approve!(current_user: current_user, approve_type: params['stash_engine_proposed_change']['related_type'])
        @proposed_change.reload
        format.js
      end
    end

    def destroy
      respond_to do |format|
        @proposed_change = authorize StashEngine::ProposedChange.find(params[:id])
        @resource = @proposed_change.identifier&.latest_resource if @proposed_change.present?
        @proposed_change.reject!(current_user: current_user)
        @proposed_change.reload
        format.js
      end
    end

    private

    def setup_paging
      @page = params[:page] || '1'
      @page_size = (params[:page_size].blank? || params[:page_size] != '1000000' ? '10' : '1000000')
    end

  end
end
