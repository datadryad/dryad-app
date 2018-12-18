require_dependency 'stash_engine/application_controller'

module StashEngine
  # rubocop:disable Metrics/ClassLength
  class AdminDatasetsController < ApplicationController
    include SharedSecurityController
    before_action :require_admin
    before_action :setup_paging, only: [:index]
    before_action :setup_ds_sorting, only: [:index]

    TENANT_IDS = Tenant.all.map(&:tenant_id)
    CURATION_STATUSES = CurationActivity.validators_on(:status).first.options[:in]

    # the admin datasets main page showing users and stats, but slightly different in scope for superusers vs tenant admins
    def index
      my_tenant_id = (current_user.role == 'admin' ? current_user.tenant_id : nil)
      @all_stats = Stats.new
      @seven_day_stats = Stats.new(tenant_id: my_tenant_id, since: (Time.new - 7.days))
      @ds_identifiers = build_table_query
      respond_to do |format|
        format.html
        format.tsv
      end
    end

    # Unobtrusive Javascript (UJS) to do AJAX by running javascript
    def status_popup
      respond_to do |format|
        @identifier = Identifier.find(params[:id])
        format.js
      end
    end

    # Unobtrusive Javascript (UJS) to do AJAX by running javascript
    def note_popup
      respond_to do |format|
        @identifier = Identifier.find(params[:id])
        format.js
      end
    end

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

    # show curation activities for this item
    def activity_log
      @identifier = Identifier.find(params[:id])
      created_at = SortableTable::SortColumnDefinition.new('created_at')
      sort_table = SortableTable::SortTable.new([created_at])
      @sort_column = sort_table.sort_column(params[:sort], params[:direction])
      @curation_activities = @identifier.curation_activities.order(@sort_column.order)
      @internal_data = InternalDatum.where(identifier_id: @identifier.id)
    end

    private

    def setup_paging
      @page = params[:page] || '1'
      @page_size = (params[:page_size].blank? || params[:page_size] != '1000000' ? '10' : '1000000')
    end

    # rubocop:disable Metrics/MethodLength
    def setup_ds_sorting
      title_sort = SortableTable::SortColumnCustomDefinition.new('title', asc: 'stash_engine_resources.title asc',
                                                                          desc: 'stash_engine_resources.title desc')
      status_sort = SortableTable::SortColumnCustomDefinition.new('status',
                                                                  asc: 'stash_engine_identifier_states.current_curation_status asc',
                                                                  desc: 'stash_engine_identifier_states.current_curation_status desc')
      author_sort = SortableTable::SortColumnCustomDefinition.new('author', asc: 'user1.last_name asc, user1.first_name asc',
                                                                            desc: 'user1.last_name desc, user1.first_name desc')
      doi_sort = SortableTable::SortColumnCustomDefinition.new('doi', asc: 'stash_engine_identifiers.identifier asc',
                                                                      desc: 'stash_engine_identifiers.identifier desc')
      last_modified_sort = SortableTable::SortColumnCustomDefinition.new('last_modified',
                                                                         asc: 'stash_engine_curation_activities.updated_at asc',
                                                                         desc: 'stash_engine_curation_activities.updated_at desc')
      modified_by_sort = SortableTable::SortColumnCustomDefinition.new('modified_by',
                                                                       asc: 'user2.last_name asc, user2.first_name asc',
                                                                       desc: 'user2.last_name desc, user2.first_name desc')
      size_sort = SortableTable::SortColumnCustomDefinition.new('size', asc: 'storage_size asc', desc: 'storage_size desc')

      sort_table = SortableTable::SortTable.new([title_sort, status_sort, author_sort, doi_sort, last_modified_sort, modified_by_sort, size_sort])
      @sort_column = sort_table.sort_column(params[:sort], params[:direction])
    end
    # rubocop:enable Metrics/MethodLength

    def build_table_query
      ds_identifiers = base_table_join
      ds_identifiers = ds_identifiers.where('stash_engine_resources.tenant_id = ?', current_user.tenant_id) if current_user.role != 'superuser'

      # We'll have to play with this search to get it to be reasonable with the insane interface so that it narrows to a small enough
      # set so that it is useful to people for finding something and a large enough set to have what they want without hunting too long.
      # It doesn't really support sorting by relevance because of the other sorts.
      ds_identifiers = ds_identifiers.where('MATCH(search_words) AGAINST(?) > 0.5', params[:q]) unless params[:q].blank?
      ds_identifiers = add_filters(query_obj: ds_identifiers)
      if request.format.tsv?
        ds_identifiers.order(@sort_column.order).page(1).per(2_000)
      else
        ds_identifiers.order(@sort_column.order).page(@page).per(@page_size)
      end
    end

    def base_table_join
      # the following simpler ActiveRecord works, but then sorting becomes ambiguous because user joined twice
      # also the joins aren't quite right because of the way itentifier state is set up and the associations
      # Identifier.joins([{ latest_resource: :user }, { identifier_state: { curation_activity: :user } }])

      # using these table aliases user1, user2 for the two different users
      Identifier.joins('INNER JOIN `stash_engine_resources` ' \
        'ON `stash_engine_identifiers`.`latest_resource_id` = `stash_engine_resources`.`id` ' \
        'INNER JOIN `stash_engine_users` user1 ' \
        'ON `stash_engine_resources`.`user_id` = user1.`id` ' \
        'INNER JOIN `stash_engine_identifier_states` ' \
        'ON `stash_engine_identifiers`.`id` = `stash_engine_identifier_states`.`identifier_id` ' \
        'INNER JOIN `stash_engine_curation_activities` ' \
        'ON `stash_engine_identifier_states`.`curation_activity_id` = `stash_engine_curation_activities`.`id` ' \
        'LEFT JOIN `stash_engine_users` user2 ' \
        'ON `stash_engine_curation_activities`.`user_id` = user2.`id`')
    end

    def add_filters(query_obj:)
      if TENANT_IDS.include?(params[:tenant]) && current_user.role == 'superuser'
        query_obj = query_obj.where('stash_engine_resources.tenant_id = ?', params[:tenant])
      end
      if CURATION_STATUSES.include?(params[:curation_status])
        query_obj = query_obj.where('stash_engine_identifier_states.current_curation_status = ?', params[:curation_status])
      end
      query_obj
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

  end
  # rubocop:enable Metrics/ClassLength
end
