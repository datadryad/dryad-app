module StashEngine
  class AdminDashboardController < ApplicationController
    helper SortableTableHelper
    before_action :require_admin
    before_action :setup_paging, only: :index
    before_action :setup_limits, only: %i[index new_search save_search]
    before_action :setup_search, only: %i[index new_search save_search]
    before_action :collect_properties, only: %i[new_search save_search]
    # before_action :load, only: %i[popup note_popup edit]

    # rubocop:disable Metrics/MethodLength
    def index
      @datasets = authorize StashEngine::Resource.latest_per_dataset
        .left_outer_joins(identifier: %i[counter_stat internal_data])
        .left_outer_joins(:last_curation_activity)
        .left_outer_joins(:authors)
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
            from stash_engine_authors sea where sea.resource_id = stash_engine_resources.id limit 6) as author_string,
          MATCH(stash_engine_identifiers.search_words) AGAINST('#{@search_string}') as relevance
        ")

      add_fields
      add_filters

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

    def new_search
      respond_to(&:js)
    end

    def save_search
      existing = authorize StashEngine::AdminSearch.find_by(id: params[:id])
      return unless existing

      existing.update(properties: @properties)
      respond_to(&:js)
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

    # rubocop:disable Style/MultilineIfModifier
    def setup_limits
      session[:admin_search_role] = params[:user_role] if params[:user_role].present?
      user_role = current_user.roles.find_by(id: session[:admin_search_role]) || current_user.roles.first
      @role_object = user_role.role_object
      @tenant_limit = @role_object.is_a?(StashEngine::Tenant) ? policy_scope(StashEngine::Tenant) : StashEngine::Tenant.enabled
      if @role_object.is_a?(StashEngine::JournalOrganization)
        sponsor_limit = [@role_object]
        sponsor_limit += @role_object.orgs_included if @role_object.orgs_included
      end
      @sponsor_limit = sponsor_limit || []
      journal_limit = @role_object.journals_sponsored_deep if @sponsor_limit.present?
      journal_limit = [@role_object] if @role_object.is_a?(StashEngine::Journal)
      @journal_limit = journal_limit || []
    end

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def setup_search
      @saved_search = current_user.admin_searches[params[:search].to_i - 1] if params[:search]
      @saved_search ||= current_user.admin_searches.find_by(default: true)

      @search_string = params[:q] || @saved_search&.search_string || session[:admin_search_string]
      @filters = params[:filters] || @saved_search&.filters || session[:admin_search_filters]
      @fields = params[:fields] || @saved_search&.fields || session[:admin_search_fields]

      session[:admin_search_filters] = params[:filters] if params[:filters].present?
      session[:admin_search_fields] = params[:fields] if params[:fields].present?
      session[:admin_search_string] = params[:q] if params[:q].present?

      return unless @fields.blank?

      @search_string = ''
      @filters = {}
      @fields = %w[doi authors metrics status submit_date publication_date]
      @fields << 'journal' if @sponsor_limit.present?
      @fields << 'identifiers' if @journal_limit.present?
      @fields << 'affiliations' if @role_object.is_a?(StashEngine::Tenant)
      @fields.push('funders', 'awards') if @role_object.is_a?(StashEngine::Funder)
      @fields.push('identifiers', 'curator').delete_at(2) if current_user.min_curator?
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def collect_properties
      @properties = { fields: @fields, filters: @filters, search_string: @search_string }.to_json
    end

    def add_fields
      @datasets = @datasets.left_outer_joins(:related_identifiers) unless @filters[:identifiers].blank?
      return unless @filters[:member].present? || @filters.dig(:funder, :value).present? || @filters.dig(:affiliation, :value).present? ||
        @role_object.is_a?(StashEngine::Tenant) || @role_object.is_a?(StashEngine::Funder)

      @datasets = @datasets.left_outer_joins(authors: :affiliations).left_outer_joins(:funders)
    end

    def add_filters
      tenant_filter
      journal_filter
      sponsor_filter
      funder_filter

      @datasets = @datasets.where('stash_engine_curation_activities.status': @filters[:status]) if @filters[:status].present?
      @datasets = @datasets.where('dcs_affiliations.ror_id': @filters.dig(:affiliation, :value)) if @filters.dig(:affiliation, :value).present?
      @datasets = @datasets.where(
        'curator.id': Integer(@filters[:curator], exception: false) ? @filters[:curator] : nil
      ) if @filters[:curator].present? && current_user.min_curator?
      @datasets = @datasets.where("MATCH(stash_engine_identifiers.search_words) AGAINST('#{@search_string}') > 0") unless @search_string.blank?
      @datasets = @datasets.where(
        'dcs_related_identifiers.related_identifier like ? or stash_engine_internal_data.value like ?',
        "%#{@filters[:identifiers]}%", "%#{@filters[:identifiers]}%"
      ) unless @filters[:identifiers].blank?

      date_filters
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
      return unless @role_object.is_a?(StashEngine::Tenant) || @filters[:member].present?

      tenant_limit = @tenant_limit
      tenant_orgs = @role_object.ror_ids if @role_object.is_a?(StashEngine::Tenant)

      if @filters[:member].present? && tenant_limit.find_by(id: @filters[:member])
        tenant_limit = tenant_limit.where(id: @filters[:member])
        tenant_orgs = StashEngine::Tenant.find(@filters[:member]).ror_ids
      end

      @datasets = @datasets.where(
        'stash_engine_resources.tenant_id in (?) or stash_engine_identifiers.payment_id in (?)
        or dcs_affiliations.ror_id in (?) or dcs_contributors.name_identifier_id in (?)',
        tenant_limit.map(&:id), tenant_limit.map(&:id), tenant_orgs, tenant_orgs
      )
    end

    def journal_filter
      return unless @journal_limit.present? || @filters.dig(:journal, :value).present?

      journal_ids = @filters.dig(:journal, :value)
      journal_ids = (@journal_limit.map(&:id).include?(journal_ids) ? journal_ids : @journal_limit.map(&:id)) if @journal_limit.present?

      @datasets = @datasets.where('stash_engine_journals.id': journal_ids) if journal_ids.present?
    end

    def sponsor_filter
      return unless @sponsor_limit.present? || @filters[:sponsor].present?

      sponsor_ids = @filters[:sponsor]
      sponsor_ids = (@sponsor_limit.map(&:id).include?(sponsor_ids) ? sponsor_ids : @sponsor_limit.map(&:id)) if @sponsor_limit.present?

      @datasets = @datasets.where('stash_engine_journals.sponsor_id': sponsor_ids) if sponsor_ids.present?
    end

    def funder_filter
      return unless @role_object.is_a?(StashEngine::Funder) || @filters.dig(:funder, :value).present?

      funder_ror = @role_object&.ror_id || @filters.dig(:funder, :value)
      @datasets = @datasets.where('dcs_contributors.name_identifier_id': funder_ror)
    end

    def date_string(date_hash)
      from = date_hash[:start_date]
      to = date_hash[:end_date]
      return "< '#{to}'" if from.blank?

      "BETWEEN '#{from}' AND #{to.blank? ? 'now()' : "'#{to}'"}"
    end
  end
end
