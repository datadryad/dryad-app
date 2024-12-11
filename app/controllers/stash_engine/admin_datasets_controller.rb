require 'stash/salesforce'

module StashEngine
  class AdminDatasetsController < ApplicationController
    helper SortableTableHelper
    before_action :require_user_login
    before_action :load, only: %i[popup note_popup edit]

    def popup
      case @field
      when 'note'
        authorize %i[stash_engine admin_datasets], :note_popup?
        @curation_activity = CurationActivity.new(
          resource_id: @resource.id,
          status: @resource.last_curation_activity&.status
        )
      when 'publication'
        authorize %i[stash_engine admin_datasets], :data_popup?
        @publication = StashEngine::ResourcePublication.find_or_create_by(resource_id: @identifier.latest_resource.id)
      when 'data'
        authorize %i[stash_engine admin_datasets], :data_popup?
        setup_internal_data_list
      when 'waiver'
        authorize %i[stash_engine admin_datasets], :waiver_add?
        @desc = 'Add fee waiver'
      end

      respond_to(&:js)
    end

    def edit
      authorize %i[stash_engine admin_datasets], :waiver_add?
      waiver_add
      respond_to(&:js)
    end

    # show curation activities for this item
    def activity_log
      authorize %i[stash_engine admin_datasets]
      @identifier = Identifier.find(params[:id])
      resource_ids = @identifier.resources.collect(&:id)
      ord = helpers.sortable_table_order(whitelist: %w[created_at])
      @curation_activities = CurationActivity.where(resource_id: resource_ids).order(ord, id: :asc)
      @internal_data = InternalDatum.where(identifier_id: @identifier.id)
    rescue ActiveRecord::RecordNotFound
      admin_path = stash_url_helpers.url_for(controller: 'stash_engine/admin_datasets', action: 'index', only_path: true)
      redirect_to admin_path, notice: "Identifier ID #{params[:id]} no longer exists."
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
      @resource = if @identifier.last_submitted_resource&.id.present?
                    Resource.includes(:identifier,
                                      :curation_activities).find(@identifier.last_submitted_resource.id)
                  else
                    @identifier.latest_resource
                  end
      # usually notes go on latest submitted, but there is none, so put it here
      @field = params[:field]
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
    end

  end

end
