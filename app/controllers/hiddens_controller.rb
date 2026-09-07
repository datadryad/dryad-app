class HiddensController < StashEngine::ApplicationController
  before_action :require_user_login
  before_action :authorize_file_actions

  def file_validation
    ids = params[:ids].split(',')
    @files = StashEngine::GenericFile.where(id: ids)
  end

  def fix_file_size
    file = StashEngine::GenericFile.find(params[:file_id])
    file.update(upload_file_size: params[:value])

    redirect_to file_validation_hidden_path(ids: params[:file_id]), notice: 'File size updated'
  end

  def validate
    file = StashEngine::GenericFile.find(params[:file_id])
    StashEngine::FileValidationService.new(file: file).validate_file

    redirect_to file_validation_hidden_path(ids: params[:file_id]), notice: 'Validation triggered successfully'
  end

  def recreate_digest
    file = StashEngine::GenericFile.find(params[:file_id])
    StashEngine::FileValidationService.new(file: file).recreate_digests

    redirect_to file_validation_hidden_path(ids: params[:file_id]), notice: 'Digests recreation triggered successfully'
  end

  private

  def authorize_file_actions
    authorize(current_user, :file_validation?, policy_class: HiddenPagesPolicy)
  end
end
