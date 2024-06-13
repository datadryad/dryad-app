module StashEngine
  class AdminDashboardController < ApplicationController
    helper SortableTableHelper
    before_action :require_user_login
    before_action :setup_paging, only: :index
    before_action :setup_search, only: :index
    # before_action :load, only: %i[popup note_popup edit]

    # rubocop:disable Metrics/MethodLength
    def index
      @datasets = StashEngine::Resource.latest_per_dataset
        .left_outer_joins(identifier: %i[counter_stat internal_data])
        .preload(identifier: %i[counter_stat internal_data])
        .left_outer_joins(:last_curation_activity)
        .preload(:last_curation_activity)
        .left_outer_joins(:authors)
        .preload(:authors)
        .joins("
          left outer join stash_engine_curation_activities seca on seca.id = (
            select ca.id from stash_engine_curation_activities ca where ca.resource_id = stash_engine_resources.id
            and ca.status in ('submitted', 'peer_review')
            order by ca.created_at limit 1
          )")
        .joins("left outer join (
            select stash_engine_users.* from stash_engine_users
            inner join stash_engine_roles on stash_engine_users.id = stash_engine_roles.user_id
              and role in ('curator', 'superuser')
          ) curator on curator.id = stash_engine_resources.current_editor_id")
        .joins("left outer join stash_engine_journals on stash_engine_internal_data.data_type = 'publicationISSN'
          and stash_engine_journals.issn like CONCAT('%', stash_engine_internal_data.value ,'%')")
        .select("
          distinct stash_engine_resources.*, stash_engine_curation_activities.status,
          stash_engine_counter_stats.unique_investigation_count, stash_engine_counter_stats.citation_count,
          stash_engine_counter_stats.unique_request_count, seca.created_at as submit_date,
          stash_engine_journals.title as journal_title, stash_engine_journals.sponsor_id, stash_engine_journals.issn,
          CONCAT_WS(' ', curator.first_name, curator.last_name) as curator_name,
          (select GROUP_CONCAT(distinct CONCAT_WS(', ', sea.author_last_name, sea.author_first_name) ORDER BY sea.author_order, sea.id separator '; ')
            from stash_engine_authors sea where sea.resource_id = stash_engine_resources.id) as author_string,
          MATCH(stash_engine_identifiers.search_words) AGAINST('#{@search_string}') as relevance
        ")

      add_fields
      add_filters
      date_filters

      order_string = 'relevance desc'
      if params[:sort].present?
        order_list = %w[title author_string status total_file_size unique_investigation_count curator_name
                        updated_at submit_date publication_date]
        order_string = helpers.sortable_table_order(whitelist: order_list)
        order_string += ', relevance desc' if @search_string.present?
      end

      @datasets = @datasets.order(order_string)
      @datasets = @datasets.page(@page).per(@page_size)

      respond_to do |format|
        format.html
        format.csv do
          headers['Content-Disposition'] = "attachment; filename=#{Time.new.strftime('%F')}_report.csv"
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

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

    def setup_search
      @search_string = params[:q] || ''
      @filters = params[:filters] || session[:admin_search_filters] || {}
      session[:admin_search_filters] = params[:filters] if params[:filters].present?
      @fields = params[:fields] || session[:admin_search_fields]
      session[:admin_search_fields] = params[:fields] if params[:fields].present?
      return unless @fields.blank?

      @fields = %w[doi keywords authors status metrics submit_date publication_date]
      @fields << 'curator' if current_user.min_curator?
    end

    def add_fields
      @datasets = @datasets.preload(:funders) if @fields.include?('funders')
      @datasets = @datasets.preload(:subjects) if @fields.include?('keywords')
      @datasets = @datasets.preload(authors: :affiliations).preload(:tenant) if @fields.include?('affiliations')
      @datasets = @datasets.preload(tenant: :ror_orgs).preload(authors: { affiliations: :ror_org }) if @fields.include?('countries')
    end

    # rubocop:disable Style/MultilineIfModifier
    def add_filters
      if @filters[:member].present? || @filters.dig(:funder, :value).present? || @filters.dig(:affiliation, :value).present?
        @datasets = @datasets.left_outer_joins(authors: :affiliations).left_outer_joins(:funders)
      end
      tenant_filter
      @datasets = @datasets.where('stash_engine_curation_activities.status': @filters[:status]) if @filters[:status].present?
      @datasets = @datasets.where(
        'curator.id': Integer(@filters[:curator], exception: false) ? @filters[:curator] : nil
      ) if @filters[:curator].present?
      @datasets = @datasets.where('stash_engine_journals.id': @filters.dig(:journal, :value)) if @filters.dig(:journal, :value).present?
      @datasets = @datasets.where('stash_engine_journals.sponsor_id': @filters[:sponsor]) if @filters[:sponsor].present?
      @datasets = @datasets.where("MATCH(stash_engine_identifiers.search_words) AGAINST('#{@search_string}') > 0") unless @search_string.blank?
      @datasets = @datasets.where('dcs_contributors.name_identifier_id': @filters.dig(:funder, :value)) if @filters.dig(:funder, :value).present?
      @datasets = @datasets.where('dcs_affiliations.ror_id': @filters.dig(:affiliation, :value)) if @filters.dig(:affiliation, :value).present?
    end

    def date_filters
      @datasets = @datasets.where(
        "stash_engine_curation_activities.updated_at #{date_string(@filters[:updated_at])}"
      ) unless @filters[:updated_at].nil? || @filters[:updated_at].values.all?(&:blank?)
      @datasets = @datasets.where(
        "seca.created_at #{date_string(@filters[:submit_date])}"
      ) unless @filters[:submit_date].nil? || @filters[:submit_date].values.all?(&:blank?)
      @datasets = @datasets.where(
        "stash_engine_resources.publication_date #{date_string(@filters[:publication_date])}"
      ) unless @filters[:publication_date].nil? || @filters[:publication_date].values.all?(&:blank?)
    end
    # rubocop:enable Style/MultilineIfModifier

    def tenant_filter
      return unless @filters[:member].present? && StashEngine::Tenant.find_by(id: @filters[:member]).present?

      tenant_orgs = StashEngine::Tenant.find(@filters[:member]).ror_ids
      @datasets = @datasets.where(
        'stash_engine_resources.tenant_id = ? or stash_engine_identifiers.payment_id = ?
        or dcs_affiliations.ror_id in (?) or dcs_contributors.name_identifier_id in (?)',
        @filters[:member], @filters[:member], tenant_orgs, tenant_orgs
      )
    end

    def date_string(date_hash)
      from = date_hash[:start_date]
      to = date_hash[:end_date]
      return "< '#{to}'" if from.blank?

      "BETWEEN '#{from}' AND #{to.blank? ? 'now()' : "'#{to}'"}"
    end
  end
end
