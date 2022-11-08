require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class RelatedIdentifiersController < ApplicationController
    before_action :set_related_identifier, only: %i[update delete]
    before_action :ajax_require_modifiable, only: %i[update create delete]

    # GET /related_identifiers/new
    def new
      @related_identifier = RelatedIdentifier.new(resource_id: params[:resource_id])
      respond_to do |format|
        format.js
      end
    end

    # POST /related_identifiers
    def create
      @related_identifier = RelatedIdentifier.new(calc_related_identifier_params)
      @related_identifier.verified = @related_identifier.live_url_valid?
      respond_to do |format|
        if @related_identifier.save
          format.js
          format.json do
            render json: @related_identifier.as_json.merge(valid_url_format: @related_identifier.valid_url_format?)
          end
        else
          format.html { render :new }
        end
      end
    end

    # PATCH/PUT /related_identifiers/1
    def update
      respond_to do |format|
        if @related_identifier.update(calc_related_identifier_params)
          @related_identifier.update(verified: @related_identifier.live_url_valid?)
          format.js
          format.json do
            render json: @related_identifier.as_json.merge(valid_url_format: @related_identifier.valid_url_format?)
          end
        else
          format.html { render :edit }
        end
      end
    end

    # DELETE /related_identifiers/1
    def delete
      @related_identifier.destroy unless params[:id] == 'new'
      respond_to do |format|
        format.js
        format.json { render json: @related_identifier }
      end
    end

    # the sidebar for ajax showing related works
    # GET /related_identifiers with param of resource_id
    def show
      respond_to do |format|
        @resource = StashEngine::Resource.where(id: params[:resource_id]).first
        format.js
      end
    end

    # TODO: EMBARGO: do we care about published vs. embargoed in this report?
    # this is a report of related identifiers in tsv
    def report
      @resources = StashEngine::Resource.joins(:related_identifiers).joins(:current_resource_state)
        .joins(:identifier).joins(:stash_version).order('stash_engine_identifiers.identifier')
        .where(stash_engine_resource_states: { resource_state: :submitted }).distinct
      respond_to do |format|
        format.tsv {}
      end
    end

    private

    # these params are now being calculated based indirect information
    def calc_related_identifier_params
      params.require(:stash_datacite_related_identifier)
      related = params[:stash_datacite_related_identifier]
      std_fmt = RelatedIdentifier.standardize_format(related[:related_identifier])
      { related_identifier: std_fmt,
        related_identifier_type: RelatedIdentifier.identifier_type_from_str(std_fmt),
        relation_type: RelatedIdentifier::WORK_TYPES_TO_RELATION_TYPE[related[:work_type]],
        work_type: related[:work_type],
        resource_id: related[:resource_id],
        id: related[:id] }
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_related_identifier
      return if params[:id] == 'new'

      @related_identifier = RelatedIdentifier.find((params[:stash_datacite_related_identifier] ? related_identifier_params[:id] : params[:id]))
      return ajax_blocked unless resource.id == @related_identifier.resource_id
    end

    def resource
      @resource ||= if params[:stash_datacite_related_identifier]
                      StashEngine::Resource.find(related_identifier_params[:resource_id])
                    else
                      @related_identifier.resource
                    end
    end

    # Only allow a trusted parameter "white list" through.
    def related_identifier_params
      params.require(:stash_datacite_related_identifier).permit(:id, :related_identifier, :related_identifier_type,
                                                                :relation_type, :related_metadata_scheme, :scheme_URI, :scheme_type,
                                                                :resource_id, :work_type, :verified)
    end
  end
end
