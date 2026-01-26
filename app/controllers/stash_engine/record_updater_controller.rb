module StashEngine
  class RecordUpdaterController < ApplicationController
    helper SortableTableHelper

    COLUMNS_MAPPER = {
      funder: %w[award_number award_uri award_title name_identifier_id contributor_name]
    }.freeze

    before_action :check_data_type
    before_action :require_user_login
    before_action :setup_filter, only: :index
    before_action :setup_paging, only: %i[index log]
    before_action :check_status, only: %i[update destroy]

    def index
      authorize RecordUpdater, policy_class: ProposedChangePolicy

      @columns = COLUMNS_MAPPER[@data_type]
      @proposed_changes = RecordUpdater.send(@data_type).pending
      apply_joins
      apply_filters
      @proposed_changes = @proposed_changes.order('record_id desc').page(@page).per(@page_size)
      return unless @proposed_changes.present?

      respond_to(&:html)
    end

    def update
      # Accept
      @proposed_change.record.update(JSON.parse(@proposed_change.update_data).merge(award_verified: true))
      @proposed_change.user = current_user
      @proposed_change.approved!
      @proposed_change.reload

      resource = @proposed_change.resource
      return unless resource.current_curation_status == 'published'

      resource.submit_to_solr
      DataciteService.new(resource).submit

      @proposed_change.reload
      respond_to(&:js)
    end

    def destroy
      # Reject
      respond_to do |format|
        @proposed_change.record.update(award_verified: true)
        @proposed_change.user = current_user
        @proposed_change.rejected!
        @proposed_change.reload
        format.js
      end
    end

    def log
      authorize RecordUpdater, policy_class: ProposedChangePolicy

      @columns = COLUMNS_MAPPER[@data_type]
      @proposed_changes = RecordUpdater.send(@data_type).where.not(status: :pending)
      apply_joins
      apply_filters

      index_params[:sort] = 'updated_at' if index_params[:sort].blank?
      index_params[:direction] = 'desc' if index_params[:direction].blank?
      ord = helpers.sortable_table_order(whitelist: ['updated_at'] + COLUMNS_MAPPER[@data_type])

      @proposed_changes = @proposed_changes.order(ord).page(@page).per(@page_size)
    end

    private

    def check_data_type
      @data_type = index_params[:data_type].to_sym

      raise(ActiveRecord::RecordNotFound) unless @data_type.in?(COLUMNS_MAPPER.keys)
    end

    def setup_paging
      @page = index_params[:page] || '1'
      @page_size = if index_params[:page_size].blank? || index_params[:page_size].to_i == 0
                     10
                   else
                     index_params[:page_size].to_i
                   end
    end

    def setup_filter
      @statuses = [OpenStruct.new(value: '', label: '*Select status*')]
      @excluded = StashEngine::CurationActivity.statuses.except(:in_progress, :processing, :embargoed, :withdrawn)
      @statuses << @excluded.keys.map do |s|
        OpenStruct.new(value: s, label: StashEngine::CurationActivity.readable_status(s))
      end
      @statuses.flatten!
    end

    def check_status
      authorize RecordUpdater, policy_class: ProposedChangePolicy
      @proposed_change = RecordUpdater.send(@data_type).pending.find(index_params[:id])
      refresh_error if @proposed_change.nil?
    end

    def apply_joins
      query = case @data_type
              when :funder
                ["JOIN dcs_contributors records on record_updaters.record_id = records.id and records.contributor_type = 'funder'"]
              end
      query << 'JOIN stash_engine_resources on records.resource_id = stash_engine_resources.id'
      query << 'JOIN stash_engine_curation_activities sa ON sa.id = stash_engine_resources.last_curation_activity_id'
      @proposed_changes = @proposed_changes.joins(query.join(' '))
    end

    def apply_filters
      if params[:search].present?
        @proposed_changes = @proposed_changes.where("JSON_SEARCH(update_data, 'one', ?) is not null",
                                                    "%#{params[:search]}%")
      end

      @proposed_changes = if params[:status].present?
                            @proposed_changes.where('sa.status': params[:status])
                          else
                            @proposed_changes.where("sa.status in (#{@excluded.map { |_x| '?' }.join(',')})", *@excluded)
                          end
    end

    def refresh_error
      @error_message = <<-HTML.chomp.html_safe
        <p>This proposed change has already been processed.</p>
        <p>Close this dialog to refresh the results.</p>
      HTML
      render :refresh_error
    end

    def index_params
      params.permit(*%i[data_type id search status page page_size sort direction])
    end
  end
end
