require_dependency 'stash_engine/application_controller'

module StashEngine
  class AdminDatasetsController < ApplicationController
    include SharedSecurityController
    before_action :require_admin
    before_action :setup_paging
    before_action :setup_ds_sorting

    TENANT_IDS = Tenant.all.map{|i| i.tenant_id }
    CURATION_STATUSES = CurationActivity.validators_on(:status).first.options[:in]

    # the admin datasets main page showing users and stats, but slightly different in scope for superusers vs tenant admins
    def index
      my_tenant_id = (current_user.role == 'admin' ? current_user.tenant_id : nil)
      @all_stats = Stats.new
      @seven_day_stats = Stats.new(tenant_id: my_tenant_id, since: (Time.new - 7.days))

      @ds_identifiers = build_table_query
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
      ds_identifiers = add_filters(query_obj: ds_identifiers)
      ds_identifiers.order(@sort_column.order).page(@page).per(@page_size)
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
        query_obj = query_obj.where("stash_engine_resources.tenant_id = ?", params[:tenant])
      end
      if CURATION_STATUSES.include?(params[:curation_status])
        query_obj = query_obj.where("stash_engine_identifier_states.current_curation_status = ?", params[:curation_status])
      end
      query_obj
    end


  end
end
