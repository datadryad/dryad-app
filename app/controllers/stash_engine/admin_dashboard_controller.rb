module StashEngine
  # rubocop:disable Metrics/ClassLength
  class AdminDashboardController < ApplicationController
    helper SortableTableHelper
    before_action :require_admin
    before_action :setup_paging, only: :index
    before_action :setup_limits, only: %i[index new_search save_search]
    before_action :setup_search, only: %i[index new_search save_search]
    before_action :collect_properties, only: %i[new_search save_search]
    # before_action :load, only: %i[popup note_popup edit]

    def index
      @datasets = authorize StashEngine::Resource.latest_per_dataset.select('distinct stash_engine_resources.*')

      add_fields
      add_filters

      if request.format.html? && (@page == 1 || session[:admin_search_count].blank?)
        session[:admin_search_count] = StashEngine::Resource.select('count(*) as total').from(@datasets).map(&:total).first
      end

      if params[:sort].present? || @search_string.present?
        order_string = 'relevance desc'
        if params[:sort].present?
          order_list = %w[title author_string status total_file_size unique_investigation_count curator_name
                          updated_at submit_date publication_date]
          order_string = helpers.sortable_table_order(whitelist: order_list)
          order_string += ', relevance desc' if @search_string.present?
        end
        @datasets = @datasets.order(order_string)
      end

      @datasets = @datasets.page(@page).per(@page_size)

      add_subqueries

      respond_to do |format|
        format.html
        format.csv do
          headers['Content-Disposition'] = "attachment; filename=#{Time.new.strftime('%F')}_report.csv"
        end
      end
    end

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
      @page = params[:page] || 1
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
      @sort = params[:sort]
      @saved_search = current_user.admin_searches[params[:search].to_i - 1] if params[:search]
      @saved_search ||= current_user.admin_searches.find_by(default: true)

      @search_string = params[:q] || @saved_search&.search_string || session[:admin_search_string]
      @filters = params[:filters] || @saved_search&.filters || session[:admin_search_filters]
      @fields = params[:fields] || @saved_search&.fields || session[:admin_search_fields]

      session[:admin_search_filters] = params[:filters] if params[:filters].present?
      session[:admin_search_fields] = params[:fields] if params[:fields].present?
      session[:admin_search_string] = params[:q] if params.key?(:q)
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
    # rubocop:enable Metrics/AbcSize

    def collect_properties
      @properties = { fields: @fields, filters: @filters, search_string: @search_string }.to_json
    end

    # rubocop:disable Metrics/MethodLength
    def add_fields
      if @fields.include?('metrics')
        @datasets = @datasets.joins('left outer join stash_engine_counter_stats stats ON stats.identifier_id = stash_engine_identifiers.id')
          .select('stats.unique_investigation_count, stats.citation_count, stats.unique_request_count')
      end
      if @filters[:status].present? || @sort == 'status' || @filters[:updated_at]&.values&.any?(&:present?)
        @datasets = @datasets.joins(:last_curation_activity)
      end
      if @filters[:submit_date]&.values&.any?(&:present?)
        @datasets = @datasets.joins(:process_date)
      elsif @sort == 'submitted'
        @datasets = @datasets.left_outer_joins(:process_date)
      end
      if @sort == 'submitted' || @filters[:submit_date]&.values&.any?(&:present?)
        @datasets = @datasets.select('IFNULL(stash_engine_process_dates.submitted, stash_engine_process_dates.peer_review) as submit_date')
      end
      if current_user.min_curator? && (@fields.include?('curator') || @filters[:curator].present?)
        @datasets = @datasets.joins("left outer join (
            select stash_engine_users.* from stash_engine_users
            inner join stash_engine_roles on stash_engine_users.id = stash_engine_roles.user_id
              and role in ('curator', 'superuser')
          ) curator on curator.id = stash_engine_resources.current_editor_id")
          .select("CONCAT_WS(' ', curator.first_name, curator.last_name) as curator_name")
      end
      if @fields.include?('authors') || @sort == 'author_string'
        @datasets = @datasets.select("(
          select GROUP_CONCAT(CONCAT_WS(', ', sea.author_last_name, sea.author_first_name) ORDER BY sea.author_order, sea.id separator '; ')
            from stash_engine_authors sea where sea.resource_id = stash_engine_resources.id limit 6
          ) as author_string")
      end
      @datasets = @datasets.select('stash_engine_curation_activities.status') if @sort == 'status'
      @datasets = @datasets.select('stash_engine_counter_stats.unique_investigation_count') if @sort == 'unique_investigation_count'
      @datasets = @datasets.select(
        "MATCH(stash_engine_identifiers.search_words) AGAINST('#{@search_string}') as relevance"
      ) if @search_string.present?
    end
    # rubocop:enable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def add_filters
      tenant_filter
      journal_filter
      sponsor_filter
      funder_filter

      @datasets = @datasets.where('stash_engine_curation_activities.status': @filters[:status]) if @filters[:status].present?
      @datasets = @datasets.joins(authors: :affiliations).where('dcs_affiliations.ror_id': @filters.dig(:affiliation, :value)) if @filters.dig(
        :affiliation, :value
      ).present?
      @datasets = @datasets.where(
        'curator.id': Integer(@filters[:curator], exception: false) ? @filters[:curator] : nil
      ) if @filters[:curator].present? && current_user.min_curator?
      @datasets = @datasets.where("MATCH(stash_engine_identifiers.search_words) AGAINST('#{@search_string}') > 0") unless @search_string.blank?
      @datasets = @datasets.left_outer_joins(:related_identifiers)
        .joins("left outer join stash_engine_internal_data msnum on
          msnum.idenmsnum.identifier_id = stash_engine_identifiers.id and msnum.data_type = 'manuscriptNumber'")
        .where(
          'dcs_related_identifiers.related_identifier like ? or msnum.value like ?',
          "%#{@filters[:identifiers]}%", "%#{@filters[:identifiers]}%"
        ) unless @filters[:identifiers].blank?

      date_filters
    end

    def date_filters
      @datasets = @datasets.where(
        "stash_engine_curation_activities.updated_at #{date_string(@filters[:updated_at])}"
      ) unless @filters[:updated_at].nil? || @filters[:updated_at].values.all?(&:blank?)
      @datasets = @datasets.where(
        "IFNULL(stash_engine_process_dates.submitted, stash_engine_process_dates.peer_review) #{date_string(@filters[:submit_date])}"
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

      @datasets = @datasets.left_outer_joins(authors: :affiliations).left_outer_joins(:funders).where(
        'stash_engine_resources.tenant_id in (?) or stash_engine_identifiers.payment_id in (?)
        or dcs_affiliations.ror_id in (?) or dcs_contributors.name_identifier_id in (?)',
        tenant_limit.map(&:id), tenant_limit.map(&:id), tenant_orgs, tenant_orgs
      )
    end

    def journal_filter
      return unless @journal_limit.present? || @filters.dig(:journal, :value).present?

      journal_ids = @filters.dig(:journal, :value)
      journal_ids = (@journal_limit.map(&:id).include?(journal_ids) ? journal_ids : @journal_limit.map(&:id)) if @journal_limit.present?

      return unless journal_ids.present?

      @datasets = @datasets.joins(identifier: :journal).where('stash_engine_journals.id': journal_ids)
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
      @datasets = @datasets.joins(
        "inner join dcs_contributors on stash_engine_resources.id = dcs_contributors.resource_id
        and dcs_contributors.contributor_type = 'funder' and dcs_contributors.name_identifier_id = '#{funder_ror}'"
      )
    end

    def date_string(date_hash)
      from = date_hash[:start_date]
      to = date_hash[:end_date]
      return "< '#{to}'" if from.blank?
      return "> '#{from}'" if to.blank?

      "BETWEEN '#{from}' AND '#{to}'"
    end

    def add_subqueries
      @datasets = @datasets.preload(:identifier)
      @datasets = @datasets.preload(:process_date) if @fields.include?('submit_date')
      @datasets = @datasets.preload(:last_curation_activity) if @fields.include?('status') || @fields.include?('updated_at')
      @datasets = @datasets.preload(:subjects) if @fields.include?('keywords')
      @datasets = @datasets.preload(:authors) if @fields.include?('authors')
      @datasets = @datasets.preload(:tenant).preload(authors: :affiliations) if @fields.include?('affiliations')
      @datasets = @datasets.preload(tenant: :ror_orgs).preload(authors: { affiliations: :ror_org }) if @fields.include?('countries')
      @datasets = @datasets.preload(:user) if @fields.include?('submitter')
      @datasets = @datasets.preload(identifier: :counter_stat) if @fields.include?('metrics')
      @datasets = @datasets.preload(identifier: :journal) if @fields.include?('journal') || @fields.include?('sponsor')
      @datasets = @datasets.preload(identifier: { journal: :sponsor }) if @fields.include?('sponsor')
      @datasets = @datasets.preload(:funders) if @fields.include?('funders')
      @datasets = @datasets.preload(:related_identifiers).preload(identifier: :manuscript_datum) if @fields.include?('identifiers')
    end

  end
  # rubocop:enable Metrics/ClassLength
end
