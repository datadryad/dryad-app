require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class TitlesController < ApplicationController
    before_action :set_title, only: [:update, :destroy]

    respond_to :json

    # GET /titles/new
    def new
      @title = Title.new
    end

    # POST /titles
    def create
      @title = Title.new(title_params)
      respond_to do |format|
        if @title.save
          format.js
        else
          format.html { render :new }
        end
      end
    end

    # PATCH/PUT /titles/1
    def update
      respond_to do |format|
        if @title.update(title_params)
          format.js { render template: 'stash_datacite/shared/update.js.erb' }
        else
          format.html { render :edit }
        end
      end
    end

    # DELETE /titles/1
    def destroy
      @title.destroy
      redirect_to titles_url, notice: 'Title was successfully destroyed.'
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_title
      @title = Title.find(title_params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def title_params
      params.require(:title).permit(:id, :title, :title_type, :resource_id)
    end
  end
end
