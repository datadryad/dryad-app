require_dependency "stash_datacite/application_controller"

module StashDatacite
  class RelatedIdentifiersController < ApplicationController
    before_action :set_related_identifier, only: [:show, :edit, :update, :destroy]

    # GET /related_identifiers
    def index
      @related_identifiers = RelatedIdentifier.all
    end

    # GET /related_identifiers/1
    def show
    end

    # GET /related_identifiers/new
    def new
      @related_identifier = RelatedIdentifier.new
    end

    # GET /related_identifiers/1/edit
    def edit
    end

    # POST /related_identifiers
    def create
      @related_identifier = RelatedIdentifier.new(related_identifier_params)

      if @related_identifier.save
        redirect_to @related_identifier, notice: 'Related identifier was successfully created.'
      else
        render :new
      end
    end

    # PATCH/PUT /related_identifiers/1
    def update
      if @related_identifier.update(related_identifier_params)
        redirect_to @related_identifier, notice: 'Related identifier was successfully updated.'
      else
        render :edit
      end
    end

    # DELETE /related_identifiers/1
    def destroy
      @related_identifier.destroy
      redirect_to related_identifiers_url, notice: 'Related identifier was successfully destroyed.'
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_related_identifier
        @related_identifier = RelatedIdentifier.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def related_identifier_params
        params.require(:related_identifier).permit(:related_identifier, :related_identifier_type_id, :relation_type_id, :resource_id)
      end
  end
end
