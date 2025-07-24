require 'stash/salesforce'

module StashEngine
  class AdminDatasetsController < ApplicationController
    helper SortableTableHelper
    before_action :require_user_login
    protect_from_forgery except: :activity_log
    before_action :load, only: %i[popup note_popup waiver_add flag edit_submitter notification_date pub_dates]

    def popup
      case @field
      when 'flag'
        authorize @resource, :flag?
      when 'notification_date'
        authorize %i[stash_engine admin_datasets], :notification_date?
      when 'note'
        authorize %i[stash_engine admin_datasets], :note_popup?
        @curation_activity = CurationActivity.new(
          resource_id: @resource.id,
          status: @resource.last_curation_activity&.status
        )
      when 'submitter'
        authorize %i[stash_engine admin_datasets], :edit_submitter?
      when 'publications'
        authorize @resource, :curate?
        setup_publications
      when 'data'
        authorize %i[stash_engine admin_datasets], :data_popup?
        setup_internal_data_list
      when 'waiver'
        authorize %i[stash_engine admin_datasets], :waiver_add?
      else
        authorize @resource, :curate?
      end
      respond_to(&:js)
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
      respond_to(&:js)
    end

    def flag
      authorize @resource
      if params[:flag].blank?
        @resource.flag.delete if @resource&.flag&.present?
      else
        attributes = { flag: params[:flag].to_sym }
        attributes[:id] = @resource.flag.id if @resource&.flag&.present?
        @resource.update(flag_attributes: attributes)
      end
      @resource.reload
      respond_to(&:js)
    end

    def index
      authorize %i[stash_engine admin_datasets]
      @identifier = Identifier.includes(
        latest_resource: %i[last_curation_activity editor], resources: %i[stash_version last_curation_activity editor]
      ).find(params[:id])
      @internal_data = InternalDatum.where(identifier_id: @identifier.id)
    rescue ActiveRecord::RecordNotFound
      admin_path = stash_url_helpers.url_for(controller: 'stash_engine/admin_datasets', action: 'index', only_path: true)
      redirect_to admin_path, notice: "Identifier ID #{params[:id]} no longer exists."
    end

    def activity_log
      @resource = Resource.find(params[:id])
      @curation_activities = @resource.curation_activities.includes(:user)
      respond_to(&:js)
    end

    def change_log
      @resource = Resource.find(params[:id])
      types = ['StashEngine::Resource', 'StashEngine::ResourcePublication',
               'StashDatacite::RelatedIdentifier', 'StashEngine::Author',
               'StashDatacite::Contributor', 'StashDatacite::Description']
      versions = CustomVersion.where(resource_id: params[:id])
      @changes = versions.where(item_type: types).where.not(event: 'create').order(:created_at).includes(:user)
      respond_to(&:js)
    end

    def file_log
      @resource = Resource.find(params[:id])
      @changes = CustomVersion.where(resource_id: params[:id], item_type: 'StashEngine::GenericFile')
        .where.not(whodunnit: 0).order(:created_at).includes(:user)
      respond_to(&:js)
    end

    def notification_date
      authorize %i[stash_engine admin_datasets]
      notification_date = params[:notification_date].to_datetime
      return error_response('Date cannot be blank') if notification_date.blank?

      delete_calculation_date = notification_date - 1.month
      delete_calculation_date = notification_date - 6.months if @resource.current_curation_status == 'peer_review'

      @curation_activity = CurationActivity.create(
        note: "Changed notification start date to #{formatted_date(delete_calculation_date)}. #{params[:curation_activity][:note]}".html_safe,
        resource_id: @resource.id, user_id: current_user.id, status: @resource.last_curation_activity&.status
      )

      @resource.process_date.update(delete_calculation_date: delete_calculation_date)
      @identifier.process_date.update(delete_calculation_date: delete_calculation_date)
      @resource.reload
      respond_to(&:js)
    end

    def edit_submitter
      authorize %i[stash_engine admin_datasets]
      user = StashEngine::User.where(orcid: params[:orcid])&.first
      if user.present?
        @resource.submitter = user.id
        @resource.reload
      else
        @error_message = 'No Dryad user found with this ORCID'
        render 'stash_engine/user_admin/update_error' and return
      end
      respond_to(&:js)
    end

    def pub_dates
      params[:resources].each do |r|
        res = StashEngine::Resource.find(r[0])
        res.update(r[1].to_unsafe_h)
      end
      @identifier.reload
      respond_to(&:js)
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

    def destroy
      identifier = Identifier.find(params[:id])
      authorize identifier

      if identifier.destroy
        redirect_to admin_dashboard_path, notice: "Dataset with DOI #{identifier.identifier} has been deleted."
      else
        redirect_to activity_log_path(identifier.id), alert: 'Dataset could not be deleted. Please try again later.'
      end
    end

    private

    def load
      @identifier = Identifier.find(params[:id])
      @resource = @identifier.latest_resource
      @field = params[:field]
    end

    def setup_publications
      @related_work = StashDatacite::RelatedIdentifier.new(resource_id: @resource.id)
      @publication = StashEngine::ResourcePublication.find_or_create_by(resource_id: @identifier.latest_resource.id, pub_type: :primary_article)
      @preprint = StashEngine::ResourcePublication.find_or_create_by(resource_id: @identifier.latest_resource.id, pub_type: :preprint)
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

  end

end
