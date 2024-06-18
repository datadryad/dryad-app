require 'stash/salesforce'

# rubocop:disable Metrics/ClassLength
module StashEngine
  class AdminDatasetsController < ApplicationController
    helper SortableTableHelper
    before_action :require_user_login
    before_action :setup_paging, only: :index
    before_action :load, only: %i[popup note_popup edit]

    TENANT_IDS = Tenant.enabled.map(&:id)

    # the admin datasets main page showing users and stats, but slightly different in scope for curators vs tenant admins
    # rubocop:disable Metrics/AbcSize
    def index
      # Limits due to the current search/filter settings are handled within CurationTableRow
      authorize %i[stash_engine admin_datasets]
      my_tenant_id = current_user.tenant_limited? ? current_user.tenants&.first&.id : nil
      @all_stats = Stats.new
      @seven_day_stats = Stats.new(tenant_id: my_tenant_id, since: (Time.new.utc - 7.days))

      if request.format.to_s == 'text/csv' # we want all the results to put in csv
        page = 1
        page_size = 1_000_000
      else
        page = @page.to_i
        page_size = @page_size.to_i
      end

      search_terms = { params: helpers.sortable_table_params, page: page.to_i, page_size: page_size.to_i }

      @datasets = AdminDatasetsPolicy::Scope.new(current_user, StashEngine::AdminDatasets::CurationTableRow, search_terms).resolve
      @publications = StashEngine::Journal.order(:title).map(&:title)
      @pub_name = params[:publication_name] || nil

      # paginate for display
      blank_results = (page.to_i - 1) * page_size.to_i
      @datasets = Array.new(blank_results, nil) + @datasets # pad out an array with empty results for earlier pages for kaminari
      @datasets = Kaminari.paginate_array(@datasets, total_count: @datasets.length).page(page).per(page_size)

      respond_to do |format|
        format.html
        format.csv do
          headers['Content-Disposition'] = "attachment; filename=#{Time.new.strftime('%F')}_report.csv"
        end
      end
    end
    # rubocop:enable Metrics/AbcSize

    def popup
      case @field
      when 'stats'
        authorize %i[stash_engine admin_datasets], :stats_popup?
      when 'note'
        authorize %i[stash_engine admin_datasets], :note_popup?
        @curation_activity = CurationActivity.new(
          resource_id: @resource.id,
          status: @resource.last_curation_activity&.status
        )
      when 'data'
        authorize %i[stash_engine admin_datasets], :data_popup?
        setup_internal_data_list
      when 'waiver'
        authorize %i[stash_engine admin_datasets], :waiver_add?
        @desc = 'Add fee waiver'
      when 'curation_activity', 'current_editor'
        authorize %i[stash_engine admin_datasets], :curation_actions?
        @desc = @field == 'curation_activity' ? 'Edit dataset status' : 'Change dataset curator'
        @curation_activity = StashEngine::CurationActivity.new(resource_id: @resource.id)
      end

      respond_to(&:js)
    end

    def edit
      case @field
      when 'waiver'
        authorize %i[stash_engine admin_datasets], :waiver_add?
        waiver_add
      when 'curation_activity'
        authorize %i[stash_engine admin_datasets], :curation_actions?
        curation_activity_change
        @curation_row = StashEngine::AdminDatasets::CurationTableRow.where(params: {}, tenant: nil, identifier_id: @resource.identifier.id).first
      when 'current_editor'
        authorize %i[stash_engine admin_datasets], :curation_actions?
        current_editor_change
      end
      respond_to(&:js)
    end

    # show curation activities for this item
    def activity_log
      authorize %i[stash_engine admin_datasets]
      @identifier = Identifier.find(params[:id])
      resource_ids = @identifier.resources.collect(&:id)
      ord = helpers.sortable_table_order(whitelist: %w[created_at])
      @curation_activities = CurationActivity.where(resource_id: resource_ids).order(ord, id: :asc)
      @internal_data = InternalDatum.where(identifier_id: @identifier.id)
    rescue ActiveRecord::RecordNotFound
      admin_path = stash_url_helpers.url_for(controller: 'stash_engine/admin_datasets', action: 'index', only_path: true)
      redirect_to admin_path, notice: "Identifier ID #{params[:id]} no longer exists."
    end

    def create_salesforce_case
      authorize %i[stash_engine admin_datasets]
      # create the case
      @identifier = Identifier.find(params[:id])
      sf_case_id = Stash::Salesforce.create_case(identifier: @identifier, owner: current_user)

      # redirect to it
      sf_url = Stash::Salesforce.case_view_url(case_id: sf_case_id)
      redirect_to(sf_url, allow_other_host: true)
    end

    private

    def setup_paging
      if request.format.csv?
        @page = 1
        @page_size = 2_000
        return
      end
      @page = params[:page] || '1'
      @page_size = if params[:page_size].blank? || params[:page_size].to_i == 0
                     10
                   else
                     params[:page_size].to_i
                   end
    end

    def load
      @identifier = Identifier.find(params[:id])
      @resource = if @identifier.last_submitted_resource&.id.present?
                    Resource.includes(:identifier,
                                      :curation_activities).find(@identifier.last_submitted_resource.id)
                  else
                    @identifier.latest_resource
                  end
      # usually notes go on latest submitted, but there is none, so put it here
      @field = params[:field]
    end

    # this sets up the select list for internal data and will not offer options for items that are only allowed once and one is present
    def setup_internal_data_list
      @internal_datum = params[:internal_datum_id] ? InternalDatum.find(params[:internal_datum_id]) : InternalDatum.new(identifier_id: @identifier.id)
      @options = StashEngine::InternalDatum.validators_on(:data_type).first.options[:in].dup
      return if params[:internal_datum_id] # do not winnow list if doing update since it's read-only and just changes the value on update

      # Get options that are only allow one item rather than multiple
      only_one_options = @options.dup
      only_one_options.delete_if { |i| StashEngine::InternalDatum.allows_multiple(i) }

      StashEngine::InternalDatum.where(identifier_id: @internal_datum.identifier_id).where(data_type: only_one_options).each do |existing_item|
        @options.delete(existing_item.data_type)
      end
    end

    def waiver_add
      if @identifier.payment_type == 'stripe'
        # if it's already invoiced, show a warning
        @error_message = 'Unable to apply a waiver to a dataset that was already invoiced.'
        render :curation_activity_error and return
      elsif params[:waiver_basis] == 'none'
        @error_message = 'No waiver message selected, so waiver was not applied.'
        render :curation_activity_error and return
      elsif params[:waiver_basis] == 'other'
        basis = 'unspecified'
        if params[:other].present?
          basis = params[:other]
        else
          @error_message = 'No waiver message selected, so waiver was not applied.'
          render :curation_activity_error and return
        end
      else
        basis = params[:waiver_basis]
      end
      @identifier.update(payment_type: 'waiver', payment_id: '', waiver_basis: basis)
    end

    def curation_activity_change
      @last_resource = @identifier.latest_resource # the last resource of all, even not submitted
      return publishing_error if @resource.id != @last_resource.id && %w[embargoed published].include?(params.dig(:curation_activity, :status))

      @last_state = @resource&.curation_activities&.last&.status
      @this_state = params.dig(:curation_activity, :status) || @last_state

      return state_error unless CurationActivity.allowed_states(@last_state).include?(@this_state)

      @note = params.dig(:curation_activity, :note)
      @resource.current_editor_id = current_user.id
      decipher_curation_activity
      @resource.publication_date = @pub_date
      @resource.hold_for_peer_review = true if @status == 'peer_review'
      @resource.peer_review_end_date = (Time.now.utc + 6.months) if @status == 'peer_review'
      @resource.save
      @resource.reload
      @resource.curation_activities << CurationActivity.create(user_id: current_user.id, status: @status, note: @note)
    end

    def decipher_curation_activity
      @status = params.dig(:curation_activity, :status)
      @pub_date = params[:publication_date]
      # If the status was nil then we are just adding a note so get the prior status
      @status = @resource.current_curation_status unless @status.present?
      case @status
      when 'published'
        publish
      when 'embargoed'
        embargo
      else
        # The user selected a different status so clear the publication date
        @pub_date = nil
      end
    end

    def publish
      if @pub_date.present? && @pub_date > Date.today.to_s
        # If the user selected published but the publication date is in the future
        # revert to embargoed status. The item will publish when the date is reached
        @status = 'embargoed'
      end

      return if @pub_date.present?

      # If the user published but did not provide a publication date then default to today
      @pub_date = Date.today.to_s

      return unless @resource.identifier.allow_blackout?

      # BUT, if the associated journal allows Blackout, default to a year from today
      @note = ' Adding 1-year blackout period due to journal settings.'
      @status = 'embargoed'
      @pub_date = (Date.today + 1.year).to_s
    end

    def embargo
      # If the user also provided a publication date and the date is today then
      # revert to published status
      @status = 'published' if @pub_date.present? && @pub_date <= Date.today.to_s
    end

    def publishing_error
      @error_message = <<-HTML.chomp.html_safe
        <p>You're attempting to embargo or publish a dataset that is being edited or hasn't successfully finished submission.</p>
        <p>The latest version submission status is <strong>#{@last_resource.current_resource_state.resource_state}</strong> for
        resource id #{@last_resource.id}.</p>
        <p>You may need to wait a minute for submission to complete if this was recently edited or submitted again.</p>
      HTML
      render :curation_activity_error
    end

    def state_error
      @error_message = <<-HTML.chomp.html_safe
        <p>You're attempting to set the curation state to <strong>#{@this_state}</strong>,
          which isn't an allowed state change from <strong>#{@last_state}</strong>.</p>
        <p>This error may indicate that you are operating on stale data--such as by holding the <strong>status</strong> dialog
        open in a separate window while making changes elsewhere (or another user has made recent changes).</p>
        <p>The most likely ways to fix this error:</p>
        <ul>
          <li>Close this dialog and re-open the dialog to set the curation status again.</li>
          <li>Or refresh the <strong>Dataset curation</strong> list by reloading the page.</li>
          <li>In some circumstances, submissions or re-submissions of metadata and files must be completed before states can update correctly,
           so waiting a minute or two may fix the problem.</li>
        </ul>
         <hr/>
        <p>Reference information -- resource id <strong>#{@resource.id}</strong> and doi <strong>#{@resource.identifier.identifier}</strong></p>
      HTML
      render :curation_activity_error
    end

    def current_editor_change
      @resource = @identifier.latest_resource
      decipher_curation_activity
      editor_id = params.dig(:current_editor, :id)
      if editor_id&.to_i == 0
        @resource.update(current_editor_id: nil)
        editor_name = 'unassigned'
        @status = 'submitted' if @resource.current_curation_status == 'curation'
      else
        @resource.update(current_editor_id: editor_id)
        editor_name = StashEngine::User.find(editor_id)&.name
      end
      @note = "Changing current editor to #{editor_name}. " + params.dig(:curation_activity, :note)
      @resource.curation_activities << CurationActivity.create(user_id: current_user.id, status: @status, note: @note)
      @resource.update_salesforce_metadata
      @resource.reload
      # Refresh the page the same way we would for a change of curation activity
      @curation_row = StashEngine::AdminDatasets::CurationTableRow.where(params: {}, tenant: nil, identifier_id: @resource.identifier.id).first
    end

  end

end
# rubocop:enable Metrics/ClassLength
