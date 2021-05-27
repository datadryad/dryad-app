require_dependency 'stash_engine/application_controller'

# rubocop:disable Metrics/ClassLength
module StashEngine
  class AdminDatasetsController < ApplicationController

    include SharedSecurityController
    helper SortableTableHelper

    before_action :require_admin
    before_action :setup_paging, only: [:index]

    TENANT_IDS = Tenant.all.map(&:tenant_id)

    # the admin datasets main page showing users and stats, but slightly different in scope for superusers vs tenant admins
    # rubocop:disable Metrics/AbcSize
    def index
      my_tenant_id = (%w[admin tenant_curator].include?(current_user.role) ? current_user.tenant_id : nil)
      tenant_limit = (%w[admin tenant_curator].include?(current_user.role) ? current_user.tenant : nil)
      journal_limit = (if current_user.role != 'superuser' &&
                        current_user.journals_as_admin.present?
                         current_user.journals_as_admin.map(&:title)
                       end)

      @all_stats = Stats.new
      @seven_day_stats = Stats.new(tenant_id: my_tenant_id, since: (Time.new.utc - 7.days))
      @datasets = StashEngine::AdminDatasets::CurationTableRow.where(params: helpers.sortable_table_params,
                                                                     tenant: tenant_limit,
                                                                     journals: journal_limit)
      @publications = @datasets.collect(&:publication_name).compact.uniq.sort { |a, b| a <=> b }
      @pub_name = params[:publication_name] || nil

      # paginate for display, but if CSV, don't paginate
      @datasets = Kaminari.paginate_array(@datasets).page(@page).per(@page_size) unless request.format.to_s == 'text/csv'

      respond_to do |format|
        format.html
        format.csv do
          headers['Content-Disposition'] = "attachment; filename=#{Time.new.strftime('%F')}_report.csv"
        end
      end
    end
    # rubocop:enable Metrics/AbcSize

    # Unobtrusive Javascript (UJS) to do AJAX by running javascript
    def data_popup
      respond_to do |format|
        @identifier = Identifier.find(params[:id])
        @internal_datum = if params[:internal_datum_id]
                            InternalDatum.find(params[:internal_datum_id])
                          else
                            InternalDatum.new(identifier_id: @identifier.id)
                          end
        setup_internal_data_list
        format.js
      end
    end

    # Unobtrusive Javascript (UJS) to do AJAX by running javascript
    def note_popup
      respond_to do |format|
        @identifier = Identifier.where(id: params[:id]).first
        resource =
          if @identifier.last_submitted_resource&.id.present?
            Resource.includes(:identifier, :curation_activities).find(@identifier.last_submitted_resource.id)
          else
            @identifier.latest_resource # usually notes go on latest submitted, but there is none, so put it here
          end
        @curation_activity = CurationActivity.new(
          resource_id: resource.id,
          status: resource.current_curation_activity.status
        )
        format.js
      end
    end

    # Unobtrusive Javascript (UJS) to do AJAX by running javascript
    def curation_activity_popup
      respond_to do |format|
        @identifier = Identifier.where(id: params[:id]).first # changed this to use identifier_id rather than resource_id
        # using the last submitted resource should apply the curation to the correct place, even with windows held open
        @resource = Resource.includes(:identifier, :curation_activities).find(@identifier.last_submitted_resource.id)
        @curation_activity = StashEngine::CurationActivity.new(resource_id: @resource.id)
        format.js
      end
    end

    def current_editor_popup
      respond_to do |format|
        @identifier = Identifier.where(id: params[:id]).first # changed this to use identifier_id rather than resource_id
        # using the last submitted resource should apply the curation to the correct place, even with windows held open
        @resource = Resource.includes(:identifier, :curation_activities).find(@identifier.last_submitted_resource.id)
        @curation_activity = StashEngine::CurationActivity.new(resource_id: @resource.id)
        format.js
      end
    end

    def current_editor_change
      respond_to do |format|
        format.js do
          editor_id = params[:resource][:current_editor][:id]
          editor_name = StashEngine::User.find(editor_id)&.name
          @identifier = Identifier.find(params[:identifier_id])
          @resource = @identifier.resources.order(id: :desc).first # the last resource of all, even not submitted
          @resource.current_editor_id = editor_id
          @note = "Changing current editor to #{editor_name}. " + params[:resource][:curation_activity][:note]
          decipher_curation_activity
          @resource.curation_activities << CurationActivity.create(user_id: current_user.id,
                                                                   status: @status,
                                                                   note: @note)
          @resource.save
          @resource.reload
          # Refresh the page the same way we would for a change of curation activity
          @curation_row = StashEngine::AdminDatasets::CurationTableRow.where(params: {}, tenant: nil, identifier_id: @resource.identifier.id).first
          render :curation_activity_change
        end
      end
    end

    # rubocop:disable Metrics/AbcSize
    def curation_activity_change
      respond_to do |format|
        format.js do
          @identifier = Identifier.find(params[:identifier_id])
          @resource = @identifier.last_submitted_resource
          @last_resource = @identifier.resources.order(id: :desc).first # the last resource of all, even not submitted

          if @resource.id != @last_resource.id && %w[embargoed published].include?(params[:resource][:curation_activity][:status])
            return publishing_error
          end

          @last_state = @resource&.curation_activities&.last&.status
          @this_state = (params[:resource][:curation_activity][:status].blank? ? @last_state : params[:resource][:curation_activity][:status])

          return state_error unless CurationActivity.allowed_states(@last_state).include?(@this_state)

          @note = params[:resource][:curation_activity][:note]
          @resource.current_editor_id = current_user.id
          decipher_curation_activity
          @resource.publication_date = @pub_date
          @resource.hold_for_peer_review = true if @status == 'peer_review'
          @resource.peer_review_end_date = (Time.now.utc + 6.months) if @status == 'peer_review'
          @resource.curation_activities << CurationActivity.create(user_id: current_user.id,
                                                                   status: @status,
                                                                   note: @note)
          @resource.save
          @resource.reload
          @curation_row = StashEngine::AdminDatasets::CurationTableRow.where(params: {}, tenant: nil, identifier_id: @resource.identifier.id).first
        end
      end
    end
    # rubocop:enable Metrics/AbcSize

    # show curation activities for this item
    def activity_log
      @identifier = Identifier.find(params[:id])
      resource_ids = @identifier.resources.collect(&:id)
      @curation_activities = CurationActivity.where(resource_id: resource_ids).order(helpers.sortable_table_order, id: :asc)
      @internal_data = InternalDatum.where(identifier_id: @identifier.id)
    rescue ActiveRecord::RecordNotFound
      admin_path = stash_url_helpers.url_for(controller: 'stash_engine/admin_datasets', action: 'index', only_path: true)
      redirect_to admin_path, notice: "Identifier ID #{params[:id]} no longer exists."
    end

    def stats_popup
      respond_to do |format|
        format.js do
          @resource = Resource.find(params[:id])
        end
      end
    end

    private

    def setup_paging
      if request.format.csv?
        @page = 1
        @page_size = 2_000
        return
      end
      @page = params[:page] || '1'
      @page_size = (params[:page_size].blank? || params[:page_size] != '1000000' ? '10' : '1000000')
    end

    # this sets up the select list for internal data and will not offer options for items that are only allowed once and one is present
    def setup_internal_data_list
      @options = StashEngine::InternalDatum.validators_on(:data_type).first.options[:in].dup
      return if params[:internal_datum_id] # do not winnow list if doing update since it's read-only and just changes the value on update

      # Get options that are only allow one item rather than multiple
      only_one_options = @options.dup
      only_one_options.delete_if { |i| StashEngine::InternalDatum.allows_multiple(i) }

      StashEngine::InternalDatum.where(identifier_id: @internal_datum.identifier_id).where(data_type: only_one_options).each do |existing_item|
        @options.delete(existing_item.data_type)
      end
    end

    def decipher_curation_activity
      @status = params[:resource][:curation_activity][:status]
      @pub_date = params[:resource][:publication_date]
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
      @note << ' Adding 1-year blackout period due to journal settings.'
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
          <li>Or refresh the <strong>Dataset Curation</strong> list by reloading the page.</li>
          <li>In some circumstances, submissions or re-submissions of metadata and files must be completed before states can update correctly,
           so waiting a minute or two may fix the problem.</li>
        </ul>
         <hr/>
        <p>Reference information -- resource id <strong>#{@resource.id}</strong> and doi <strong>#{@resource.identifier.identifier}</strong></p>
      HTML
      render :curation_activity_error
    end

  end

end
# rubocop:enable Metrics/ClassLength
