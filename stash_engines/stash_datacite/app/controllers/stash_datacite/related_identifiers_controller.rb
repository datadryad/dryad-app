require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class RelatedIdentifiersController < ApplicationController
    before_action :set_related_identifier, only: [:update]

    # GET /related_identifiers/new
    def new
      @related_identifier = RelatedIdentifier.new(resource_id: params[:resource_id])
      respond_to do |format|
        format.js
      end
    end

    # POST /related_identifiers
    def create
      @related_identifier = RelatedIdentifier.new(related_identifier_params)
      respond_to do |format|
        if @related_identifier.save
          format.js
        else
          format.html { render :new }
        end
      end
    end

    # PATCH/PUT /related_identifiers/1
    def update
      respond_to do |format|
        if @related_identifier.update(related_identifier_params)
          format.js { render template: 'stash_datacite/shared/update.js.erb' }
        else
          format.html { render :edit }
        end
      end
    end

    # DELETE /related_identifiers/1
    def delete
      unless params[:id] == 'new'
        @related_identifier = RelatedIdentifier.find(params[:id])
        @related_identifier.destroy
      end
      respond_to do |format|
        format.js
      end
    end

    # TODO: EMBARGO: do we care about published vs. embargoed in this report?
    # this is a report of related identifiers in tsv
    def report
      @resources = StashEngine::Resource.joins(:related_identifiers).joins(:current_resource_state).
          joins(:identifier).joins(:stash_version).order('stash_engine_identifiers.identifier').
          where(stash_engine_resource_states: { resource_state:  :submitted }).distinct
      respond_to do |format|
        format.tsv { }
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_related_identifier
      @related_identifier = RelatedIdentifier.find(related_identifier_params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def related_identifier_params
      params.require(:related_identifier).permit(:id, :related_identifier, :related_identifier_type,
                                                 :relation_type, :related_metadata_scheme, :scheme_URI, :scheme_type,
                                                 :resource_id)
    end
  end
end
