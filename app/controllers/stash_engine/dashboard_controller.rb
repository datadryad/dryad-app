module StashEngine
  class DashboardController < ApplicationController
    before_action :require_login, only: %i[show user_datasets]
    before_action :ensure_tenant, only: %i[show]
    protect_from_forgery except: %i[user_datasets primary_article]

    def choose
      return redirect_to admin_dashboard_path if current_user&.min_admin?

      redirect_to dashboard_path
    end

    def show
      @doi = CGI.escape(params[:doi] || '')
    end

    def user_datasets
      @page = params[:page] || '1'
      @page_size = params[:page_size] || '10'
      respond_to do |format|
        format.js do
          @datasets = current_user.resources.latest_per_dataset.distinct
            .joins(:last_curation_activity)
            .select("stash_engine_resources.*,
            CASE
              WHEN status in ('action_required', 'awaiting_payment') THEN 0
              WHEN (status='in_progress' and (current_editor_id = #{current_user.id} or  current_editor_id is null)) THEN 0
              WHEN (status='in_progress' and current_editor_id in (#{StashEngine::User.all_curators.map(&:id).join(',').presence || '-1'})) THEN 3
              WHEN status='in_progress' THEN 1
              WHEN status='peer_review' THEN 2
              WHEN status in ('queued', 'curation', 'processing') THEN 3
              WHEN status='withdrawn' THEN 5
              ELSE 4
            END as sort_order")
            .order('sort_order asc, stash_engine_resources.updated_at desc').page(@page).per(@page_size)
          @datasets = @datasets.preload(%i[last_curation_activity stash_version current_resource_state identifier])
            .includes(:resource_type, :users, :editor, identifier: :resources)
        end
      end
    end

    def contact_helpdesk
      respond_to(&:js)
    end

    def primary_article
      @related_work = StashDatacite::RelatedIdentifier.new(resource_id: params[:resource_id], work_type: :primary_article)
      @publication = StashEngine::ResourcePublication.find_or_create_by(resource_id: params[:resource_id], pub_type: :primary_article)
      respond_to(&:js)
    end

    def save_primary_article
      resource = StashEngine::Resource.find_by(id: params.dig(:primary_article, :resource_id))
      std_fmt = StashDatacite::RelatedIdentifier.standardize_format(params.dig(:primary_article, :related_identifier))
      bare_doi = Stash::Import::Crossref.bare_doi(doi_string: std_fmt)

      cr = Stash::Import::Crossref.query_by_doi(resource: resource, doi: bare_doi)
      cr.populate_pub_update! if cr.present?
      @publication = resource.resource_publication
      @related_work = StashDatacite::RelatedIdentifier.create(
        resource_id: params.dig(:primary_article, :resource_id), work_type: :primary_article,
        relation_type: 'iscitedby', related_identifier: std_fmt,
        related_identifier_type: StashDatacite::RelatedIdentifier.identifier_type_from_str(std_fmt)
      )
      respond_to(&:js)
    end

    # methods below are private
    private

    # some people seem to get to the dashboard without having their tenant set.
    def ensure_tenant
      return unless current_user && current_user.tenant_id.blank?

      redirect_to choose_sso_path, alert: 'You must choose if you are associated with an institution before continuing'
    end

    def create_missing_email_address
      current_user.update(email: current_user.old_dryad_email) if current_user.email.blank? && !current_user.old_dryad_email.blank?
    end

  end
end
