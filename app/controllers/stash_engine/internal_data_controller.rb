module StashEngine
  class InternalDataController < ApplicationController
    # I don't believe the following is used except as a test, internal data list is currently in the admin datasets
    # controller with some other things on the same page.
    # GET /identifiers/:identifier_id/internal_data
    before_action :require_user_login

    def index
      ident = Identifier.find_with_id(Resource.find_by!(id: params[:resource_id]).identifier_str)
      @internal_data = authorize InternalDatum.where(identifier_id: ident.identifier_id) unless ident.blank?
      respond_to do |format|
        format.html
        format.json { render json: @internal_data }
      end
    end

    # POST /identifiers/:identifier_id/internal_data
    def create
      @identifier = authorize Identifier.find(params[:identifier_id]), policy_class: InternalDatumPolicy
      respond_to do |format|
        format.js do
          # right now, the only way to add is by ajax, UJS, so Javascript from the dataset admin area
          InternalDatum.create(identifier_id: @identifier.id, data_type: params[:stash_engine_internal_datum][:data_type],
                               value: params[:stash_engine_internal_datum][:value])
          @internal_data = InternalDatum.where(identifier_id: @identifier.id)
        end
      end
    end

    # PUT /internal_data/:id
    def update
      @internal_datum = authorize InternalDatum.find(params[:id])
      @identifier = @internal_datum.stash_identifier
      respond_to do |format|
        format.js do
          # right now, the only way to add is by ajax, UJS, so Javascript from the dataset admin area
          # can not change type or identifier, just the value after creating
          @internal_datum.update(value: params[:stash_engine_internal_datum][:value])
          @internal_data = InternalDatum.where(identifier_id: @identifier.id)
        end
      end
    end

    # DELETE /internal_data/:id
    def destroy
      @internal_datum = authorize InternalDatum.find(params[:id])
      @identifier_id = @internal_datum.identifier_id
      respond_to do |format|
        format.js do
          @internal_datum.destroy
          @internal_data = InternalDatum.where(identifier_id: @identifier_id)
        end
      end
    end

  end
end
