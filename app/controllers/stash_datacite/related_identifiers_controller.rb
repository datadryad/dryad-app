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
      @related_identifier = RelatedIdentifier.find(params[:id])
      @related_identifier.destroy
      respond_to do |format|
        format.js
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_related_identifier
      @related_identifier = RelatedIdentifier.find(related_identifier_params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def related_identifier_params
      params.require(:related_identifier).permit(:id, :related_identifier, :related_identifier_type_id,
                                                 :relation_type_id, :resource_id)
    end
  end
end
