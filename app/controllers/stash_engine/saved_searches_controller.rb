module StashEngine
  class SavedSearchesController < ApplicationController
    before_action :require_user_login, except: :new

    def index
      current_user.admin_searches.each { |s| s.create_code unless s.share_code.present? }
    end

    def new
      @properties = params[:properties]
      respond_to(&:js)
    end

    def create
      @saved_search = authorize StashEngine::SavedSearch.create(create_params)
      @saved_search.create_code

      if params[:type] == 'StashEngine::AdminSearch'
        @index = current_user.admin_searches.length
        render template: 'stash_engine/admin_dashboard/save_search' and return
      end

      respond_to(&:js)
    end

    def edit
      @saved_search = authorize StashEngine::SavedSearch.find_by(id: params[:id])
      @index = current_user.admin_searches.map(&:id).index(@saved_search.id) if @saved_search.is_a?(StashEngine::AdminSearch)
      respond_to(&:js)
    end

    def update
      @saved_search = authorize StashEngine::SavedSearch.find_by(id: params[:id])
      @saved_search.update(update_params)
      respond_to { |format| format.js { render inline: 'location.reload();' } }
    end

    def destroy
      existing = authorize StashEngine::SavedSearch.find_by(id: params[:id])
      existing.destroy!
      respond_to { |format| format.js { render inline: 'location.reload();' } }
    end

    private

    def create_params
      params.permit(:type, :user_id, :default, :title, :description, :properties)
    end

    def update_params
      params.permit(:default, :title, :description)
    end

  end
end
