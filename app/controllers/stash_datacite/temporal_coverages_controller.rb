module StashDatacite
  class TemporalCoveragesController < ApplicationController
    before_action :set_temporal_coverage, only: %i[update destroy]
    before_action :ajax_require_modifiable, only: %i[update destroy]

    respond_to :json

    # GET /temporal_coverages/new
    def new
      @temporal_coverage = TemporalCoverage.new
    end

    # PATCH/PUT /temporal_coverages/1
    def update
      items = temporal_coverage_params
      respond_to do |format|
        if @temporal_coverage.update(items)
          format.js { render template: 'stash_datacite/shared/update.js.erb' }
        else
          format.html { render :edit }
        end
      end
    end

    # DELETE /temporal_coverages/1
    def destroy
      @temporal_coverage.destroy
      redirect_to temporal_coverages_url, notice: 'Temporal coverage was successfully destroyed.'
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_temporal_coverage
      @temporal_coverage = TemporalCoverage.find(temporal_coverage_params[:id])
      return ajax_blocked unless resource.id == @temporal_coverage.resource_id
    end

    def resource
      @resource ||= (params[:temporal_coverage] ? StashEngine::Resource.find(temporal_coverage_params[:resource_id]) : @temporal_coverage.resource)
    end

    # Only allow a trusted parameter "white list" through.
    def temporal_coverage_params
      params.require(:temporal_coverage).permit(:id, :temporal_coverage, :resource_id)
    end
  end
end
