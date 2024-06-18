module StashEngine
  class SavedSearchesController < ApplicationController
    def index?; end

    def create
      @saved_search = StashEngine::SavedSearch.create(create_params)
      @index = current_user.admin_searches.length
      return unless params[:type] == 'StashEngine::AdminSearch'

      render template: 'stash_engine/admin_dashboard/save_search'
    end

    def edit
      @saved_search = StashEngine::SavedSearch.find_by(id: params[:id])
      @index = current_user.admin_searches.map(&:id).index(@saved_search.id)
      return unless @saved_search&.type == 'StashEngine::AdminSearch'

      render template: 'stash_engine/user_account/search_form'
    end

    def update
      @saved_search = StashEngine::SavedSearch.find_by(id: params[:id])
      return unless @saved_search&.type == 'StashEngine::AdminSearch'

      @saved_search.update(update_params)
      render template: 'stash_engine/user_account/edit'
    end

    def destroy
      existing = StashEngine::SavedSearch.find_by(id: params[:id])
      return unless existing&.type == 'StashEngine::AdminSearch'

      existing.destroy!
      render template: 'stash_engine/user_account/edit'
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
