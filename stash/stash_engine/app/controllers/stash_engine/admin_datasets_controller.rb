require_dependency 'stash_engine/application_controller'

module StashEngine
  # rubocop:disable Metrics/ClassLength
  class AdminDatasetsController < ApplicationController

    include SharedSecurityController
    include StashEngine::Concerns::Sortable

    before_action :require_admin
    before_action :setup_paging, only: [:index]
    before_action :setup_ds_sorting, only: [:index]

    TENANT_IDS = Tenant.all.map(&:tenant_id)

    # the admin datasets main page showing users and stats, but slightly different in scope for superusers vs tenant admins
    # rubocop:disable Metrics/AbcSize
    def index
      my_tenant_id = (current_user.role == 'admin' ? current_user.tenant_id : nil)
      @all_stats = Stats.new
      @seven_day_stats = Stats.new(tenant_id: my_tenant_id, since: (Time.new.utc - 7.days))

      @datasets = StashEngine::AdminDatasets::CurationTableRow.where(params)
      @datasets = @datasets.select { |rec| rec.tenant_id == current_user.tenant_id } unless current_user.superuser?

      @publications = @datasets.collect(&:publication_name).compact.uniq.sort { |a, b| a <=> b }
      @pub_name = params[:publication_name] || nil

      @datasets = Kaminari.paginate_array(@datasets).page(@page).per(@page_size)

      respond_to do |format|
        format.html
        format.csv
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
        resource = Resource.includes(:identifier, :curation_activities).find(params[:id])
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
        @resource = Resource.includes(:identifier, :curation_activities).find(params[:id])
        @curation_activity = StashEngine::CurationActivity.new(resource_id: @resource.id)
        format.js
      end
    end

    def curation_activity_change
      respond_to do |format|
        format.js do
          @note = params[:resource][:curation_activity][:note]
          @resource = Resource.find(params[:id])
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
        end
      end
    end

    # show curation activities for this item
    def activity_log
      @identifier = Identifier.find(params[:id])
      created_at = SortableTable::SortColumnDefinition.new('created_at')
      sort_table = SortableTable::SortTable.new([created_at])
      @sort_column = sort_table.sort_column(params[:sort], params[:direction])
      resource_ids = @identifier.resources.collect(&:id)
      @curation_activities = CurationActivity.where(resource_id: resource_ids).order(@sort_column.order, id: :asc)
      @internal_data = InternalDatum.where(identifier_id: @identifier.id)
    end

    private

    def setup_ds_sorting
      sort_table = SortableTable::SortTable.new(
        [sort_column_definition('title', nil, %w[title]),
         sort_column_definition('status', nil, %w[status]),
         sort_column_definition('author_names', nil, %w[author_names]),
         sort_column_definition('identifier', nil, %w[identifier]),
         sort_column_definition('updated_at', nil, %w[updated_at]),
         sort_column_definition('editor_name', nil, %w[editor_name]),
         sort_column_definition('storage_size', nil, %w[storage_size]),
         sort_column_definition('publication_date', nil, %w[publication_date])]
      )
      @sort_column = sort_table.sort_column(params[:sort], params[:direction])
    end

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

  end
  # rubocop:enable Metrics/ClassLength
end
