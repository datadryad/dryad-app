class HiddensController < StashEngine::ApplicationController
  before_action :require_superuser

  def file_validation
    ids = params[:ids].split(',')
    @files = StashEngine::GenericFile.where(id: ids)
  end
end