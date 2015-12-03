require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class ContributorsController < ApplicationController
    before_action :set_contributor, only: [:show, :edit, :update, :destroy]

    # GET /contributors
    def index
      @contributors = Contributor.all
    end

    # GET /contributors/1
    def show
    end

    # GET /contributors/new
    def new
      @contributor = Contributor.new
    end

    # GET /contributors/1/edit
    def edit
    end

    # POST /contributors
    def create
      @contributor = Contributor.new(contributor_params)

      if @contributor.save
        redirect_to @contributor, notice: 'Contributor was successfully created.'
      else
        render :new
      end
    end

    # PATCH/PUT /contributors/1
    def update
      if @contributor.update(contributor_params)
        redirect_to @contributor, notice: 'Contributor was successfully updated.'
      else
        render :edit
      end
    end

    # DELETE /contributors/1
    def destroy
      @contributor.destroy
      redirect_to contributors_url, notice: 'Contributor was successfully destroyed.'
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_contributor
      @contributor = Contributor.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def contributor_params
      params.require(:contributor).permit(:contributor_name, :contributor_type, :name_identifier_id,
                                          :affliation_id, :resource_id)
    end
  end
end
