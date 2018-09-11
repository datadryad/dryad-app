require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class ContributorsController < ApplicationController
    before_action :set_contributor, only: %i[update delete]
    before_action :ajax_require_modifiable, only: %i[update create delete]

    # GET /contributors/new
    def new
      @contributor = Contributor.new(resource_id: params[:resource_id])
      respond_to do |format|
        format.js
      end
    end

    # POST /contributors
    def create
      @contributor = Contributor.new(contributor_params)
      respond_to do |format|
        if @contributor.save
          format.js
        else
          format.html { render :new }
        end
      end
    end

    # PATCH/PUT /contributors/1
    def update
      respond_to do |format|
        if @contributor.update(contributor_params)
          format.js { render template: 'stash_datacite/shared/update.js.erb' }
        else
          format.html { render :edit }
        end
      end
    end

    # DELETE /contributors/1
    def delete
      unless params[:id] == 'new'
        @contributor = Contributor.find(params[:id])
        @contributor.destroy
      end
      respond_to do |format|
        format.js
      end
    end

    private

    def resource
      @resource ||= (params[:contributor] ? StashEngine::Resource.find(contributor_params[:resource_id]) : @contributor.resource)
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_contributor
      return if params[:id] == 'new'
      @contributor = Contributor.find((params[:contributor] ? contributor_params[:id] : params[:id]))
      return ajax_blocked unless resource.id == @contributor.resource_id
    end

    # Only allow a trusted parameter "white list" through.
    def contributor_params
      params.require(:contributor).permit(:id, :contributor_name, :contributor_type, :name_identifier_id,
                                          :affiliation_id, :award_number, :resource_id)
    end
  end
end
