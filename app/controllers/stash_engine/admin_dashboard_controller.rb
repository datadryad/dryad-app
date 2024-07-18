module StashEngine
  # rubocop:disable Metrics/ClassLength
  class AdminDashboardController < ApplicationController
    helper SortableTableHelper
    before_action :require_admin
    protect_from_forgery except: :results
    before_action :setup_paging, only: %i[results]
    before_action :setup_limits, only: %i[index results]
    before_action :setup_search, only: %i[index results]
    before_action :load, only: %i[edit update]

    def index; end

    def results
      @datasets = StashEngine::Resource.latest_per_dataset.select(
        :id, :title, :total_file_size, :user_id, :tenant_id, :identifier_id, :last_curation_activity_id, :publication_date,
        :current_editor_id, :current_resource_state_id
      ).distinct

      add_fields
      add_filters

      @sql = @datasets.to_sql

      if params[:sort].present? || @search_string.present?
        order_string = 'relevance desc'
        if params[:sort].present?
          order_list = %w[title author_string status total_file_size view_count curator_name
                          updated_at submit_date publication_date first_sub_date first_pub_date queue_date]
          order_string = helpers.sortable_table_order(whitelist: order_list)
          order_string = "stash_engine_curation_activities.#{order_string}" if @sort == 'updated_at'
          order_string += ', relevance desc' if @search_string.present?
        end
        @datasets = @datasets.order(order_string)
      end

      @datasets = @datasets.page(@page).per(@page_size)

      respond_to do |format|
        format.js do
          add_subqueries
          collect_properties
        end
        format.csv do
          headers['Content-Disposition'] = "attachment; filename=#{Time.new.strftime('%F')}_report.csv"
        end
      end
    end

    def count
      if session[:admin_search_count].blank?
        session[:admin_search_count] = StashEngine::Resource.select('count(*) as total').from("(#{params[:sql]}) subquery").map(&:total).first
      end
      @count = session[:admin_search_count]
      respond_to(&:js)
    end

    def new_search
      @properties = params[:properties]
      respond_to(&:js)
    end

    def save_search
      existing = authorize StashEngine::AdminSearch.find_by(id: params[:id])
      return unless existing

      existing.update!(properties: params[:properties])
      respond_to(&:js)
    end

    def edit
      @desc = @field == 'curation_activity' ? 'Edit dataset status' : 'Change dataset curator'
      @curation_activity = StashEngine::CurationActivity.new(resource_id: @resource.id)
      respond_to(&:js)
    end

    def update
      curation_activity_change if @field == 'curation_activity'
      current_editor_change if @field == 'current_editor'
      respond_to(&:js)
    end

    private

    def collect_properties
      @properties = { fields: @fields, filters: @filters, search_string: @search_string }.to_json
    end

    def setup_paging
      if request.format.csv?
        @page = 1
        @page_size = 10_000
        return
      end
      @page = params[:page] || 1
      @page_size = 10 if params[:page_size].blank? || params[:page_size].to_i == 0
      @page_size ||= params[:page_size].to_i
    end

    # rubocop:disable Style/MultilineIfModifier
    def setup_limits
      session[:admin_search_role] = params[:user_role] if params[:user_role].present?
      @user_role = current_user.roles.find_by(id: session[:admin_search_role]) || current_user.roles.first
      @role_object = @user_role.role_object
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
      @search = params[:search].to_i
      session[:admin_search_count] = nil if @page == 1
      session[:admin_search_filters] = nil if params[:clear]
      session[:admin_search_fields] = nil if params[:clear]
      session[:admin_search_string] = nil if params[:clear]
      @saved_search = current_user.admin_searches[@search - 1] if params[:search]
      @saved_search ||= current_user.admin_searches.find_by(default: true)

      @search_string = params[:q] || session[:admin_search_string] || @saved_search&.search_string
      @filters = params[:filters] || session[:admin_search_filters] || @saved_search&.filters
      @filters = @filters.deep_transform_keys(&:to_sym) unless @filters.blank?
      @fields = params[:fields] || session[:admin_search_fields] || @saved_search&.fields

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
      @fields.push('identifiers', 'curator', 'queue_date').delete_at(2) if current_user.min_curator?
    end

    def add_fields
      if @sort == 'view_count'
        @datasets = @datasets.joins(
          'left outer join stash_engine_counter_stats stats ON stats.identifier_id = stash_engine_identifiers.id'
        ).select('stats.unique_investigation_count as view_count')
      end
      if @filters[:status].present? || %w[status updated_at].include?(@sort) || @filters[:updated_at]&.values&.any?(&:present?)
        @datasets = @datasets.joins(:last_curation_activity)
      end
      if current_user.min_app_admin? && (@fields.include?('curator') || @filters[:curator].present?)
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
      date_fields
      @datasets = @datasets.select('stash_engine_curation_activities.status') if @sort == 'status'
      @datasets = @datasets.select('stash_engine_curation_activities.updated_at') if @sort == 'updated_at'
      @datasets = @datasets.select(
        "MATCH(stash_engine_identifiers.search_words) AGAINST('#{
          %r{^10.[\S]+/[\S]+$}.match(@search_string) ? "\"#{@search_string}\"" : @search_string
        }') as relevance"
      ) if @search_string.present?
    end

    def date_fields
      if @filters[:submit_date]&.values&.any?(&:present?)
        @datasets = @datasets.joins(:process_date).select('stash_engine_process_dates.processing as submit_date')
      elsif @sort == 'submit_date'
        @datasets = @datasets.left_outer_joins(:process_date).select('stash_engine_process_dates.processing as submit_date')
      end
      return unless @sort == 'first_pub_date' || @filters[:first_pub_date]&.values&.any?(&:present?)

      @datasets = @datasets.select('stash_engine_identifiers.publication_date as first_pub_date')
    end

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
      ) if @filters[:curator].present? && current_user.min_app_admin?
      unless @search_string.blank?
        @datasets = @datasets.where("MATCH(stash_engine_identifiers.search_words) AGAINST('#{
          %r{^10.[\S]+/[\S]+$}.match(@search_string) ? "\"#{@search_string}\"" : @search_string
        }') > 0")
      end
      @datasets = @datasets.left_outer_joins(:related_identifiers)
        .joins("left outer join stash_engine_internal_data msnum on
          msnum.identifier_id = stash_engine_identifiers.id and msnum.data_type = 'manuscriptNumber'")
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
        "stash_engine_process_dates.processing #{date_string(@filters[:submit_date])}"
      ) unless @filters[:submit_date].nil? || @filters[:submit_date].values.all?(&:blank?)
      if %w[first_sub_date queue_date].include?(@sort) || @filters[:first_sub_date]&.values&.any?(&:present?)
        filter_on = @filters[:first_sub_date]&.values&.any?(&:present?)
        @datasets = @datasets.joins(
          "#{filter_on ? '' : 'LEFT OUTER '}JOIN stash_engine_process_dates id_dates ON id_dates.processable_type = 'StashEngine::Identifier'
            AND id_dates.processable_id = stash_engine_identifiers.id
          #{filter_on ? " AND IFNULL(id_dates.processing, id_dates.submitted) #{date_string(@filters[:first_sub_date])}" : ''}"
        ).select('IFNULL(id_dates.processing, id_dates.submitted) as first_sub_date, id_dates.submitted as queue_date')
      end
      @datasets = @datasets.where(
        "stash_engine_resources.publication_date #{date_string(@filters[:publication_date])}"
      ) unless @filters[:publication_date].nil? || @filters[:publication_date].values.all?(&:blank?)
      @datasets = @datasets.where(
        "stash_engine_identifiers.publication_date #{date_string(@filters[:first_pub_date])}"
      ) unless @filters[:first_pub_date].nil? || @filters[:first_pub_date].values.all?(&:blank?)
    end
    # rubocop:enable Style/MultilineIfModifier, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/AbcSize

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

      journal_ids = @filters.dig(:journal, :value)&.to_i
      journal_ids = (@journal_limit.map(&:id).include?(journal_ids) ? journal_ids : @journal_limit.map(&:id)) if @journal_limit.present?

      @datasets = @datasets.joins(identifier: :journal).where('stash_engine_journals.id': journal_ids) if journal_ids.present?
    end

    def sponsor_filter
      return unless @sponsor_limit.present? || @filters[:sponsor].present?

      sponsor_ids = @filters[:sponsor]&.to_i
      sponsor_ids = (@sponsor_limit.map(&:id).include?(sponsor_ids) ? sponsor_ids : @sponsor_limit.map(&:id)) if @sponsor_limit.present?

      @datasets = @datasets.joins(identifier: :journal).where('stash_engine_journals.sponsor_id': sponsor_ids) if sponsor_ids.present?
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
      return "<= '#{to}'" if from.blank?
      return ">= '#{from}'" if to.blank?

      "BETWEEN '#{from}' AND '#{to}'"
    end

    def add_subqueries
      @datasets = @datasets.preload(:identifier).preload(:current_resource_state)
      @datasets = @datasets.preload(:process_date) if @fields.include?('submit_date')
      @datasets = @datasets.preload(identifier: :process_date) if @fields.intersect?(%w[first_sub_date queue_date])
      @datasets = @datasets.preload(:last_curation_activity) if @fields.include?('status') || @fields.include?('updated_at')
      @datasets = @datasets.preload(:subjects) if @fields.include?('keywords')
      @datasets = @datasets.preload(:authors) if @fields.include?('authors')
      @datasets = @datasets.preload(:tenant).preload(authors: :affiliations) if @fields.include?('affiliations')
      @datasets = @datasets.preload(tenant: :ror_orgs).preload(authors: { affiliations: :ror_org }) if @fields.include?('countries')
      @datasets = @datasets.preload(:user) if @fields.include?('submitter')
      @datasets = @datasets.preload(identifier: :counter_stat) if @fields.include?('metrics')
      @datasets = @datasets.preload(identifier: :journal_datum) if @fields.include?('journal') || @fields.include?('sponsor')
      @datasets = @datasets.preload(:funders) if @fields.include?('funders')
      @datasets = @datasets.preload(:related_identifiers).preload(identifier: :manuscript_datum) if @fields.include?('identifiers')
    end

    def load
      @identifier = Identifier.find(params[:id])
      @resource = authorize @identifier.latest_resource, :curate?
      @field = params[:field]
      @last_state = @resource.last_curation_activity.status
      @status = params.dig(:curation_activity, :status).presence || @last_state
    end

    def curation_activity_change
      return publishing_error if @resource.id != @identifier.last_submitted_resource.id &&
        %w[embargoed published].include?(params.dig(:curation_activity, :status))

      return state_error unless CurationActivity.allowed_states(@last_state).include?(@status)

      decipher_curation_activity
      @note = params.dig(:curation_activity, :note)
      @resource.current_editor_id = current_user.id
      @resource.publication_date = @pub_date
      @resource.hold_for_peer_review = true if @status == 'peer_review'
      @resource.peer_review_end_date = (Time.now.utc + 6.months) if @status == 'peer_review'
      @resource.save
      @resource.curation_activities << CurationActivity.create(user_id: current_user.id, status: @status, note: @note)
      @resource.reload
    end

    def decipher_curation_activity
      @pub_date = params[:publication_date]
      case @status
      when 'published'
        publish
      when 'embargoed'
        @status = 'published' if @pub_date.present? && @pub_date <= Time.now.utc.to_date.to_s
      else
        @pub_date = nil
      end
    end

    def publish
      @status = 'embargoed' if @pub_date.present? && @pub_date > Time.now.utc.to_date.to_s
      return if @pub_date.present?

      @pub_date = Time.now.utc.to_date.to_s
      return unless @identifier.allow_blackout?

      @note = 'Adding 1-year blackout period due to journal settings.'
      @status = 'embargoed'
      @pub_date = (Time.now.utc.to_date + 1.year).to_s
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
        <p>You're attempting to set the curation state to <strong>#{@status}</strong>,
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
      editor_id = params.dig(:current_editor, :id)
      if editor_id&.to_i == 0
        @resource.update(current_editor_id: nil)
        @status = 'submitted' if @resource.current_curation_status == 'curation'
        @curator_name = ''
      else
        @resource.update(current_editor_id: editor_id)
        @curator_name = StashEngine::User.find(editor_id)&.name
      end
      @note = "Changing current editor to #{@curator_name.presence || 'unassigned'}. " + params.dig(:curation_activity, :note)
      @resource.curation_activities << CurationActivity.create(user_id: current_user.id, status: @status, note: @note)
      @resource.reload
    end

  end
  # rubocop:enable Metrics/ClassLength
end
