class FeeRecordController < StashEngine::ApplicationController
  before_action :require_user_login

  def show
    @receipt = authorize FeeRecord.find_by(id: params[:id])

    respond_to(&:js)
  end
end
