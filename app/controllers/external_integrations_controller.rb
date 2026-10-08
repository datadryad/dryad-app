class ExternalIntegrationsController < ApplicationController

  def form
    @integration = ExternalIntegration.find_or_initialize_by(
      integration: params[:integration],
      integrator_id: params[:integrator_id],
      integrator_type: params[:integrator_type]
    )
    render :form
  end

  def create
    @integration = ExternalIntegration.create permit_params
    if @integration.errors.any?
      @error_message = @integration.errors.full_messages.first
      render 'stash_engine/user_admin/update_error' and return
    end
    render :close_modal
  end

  def update
    @integration = ExternalIntegration.find permit_params[:id]
    @integration.update permit_params
    if @integration.errors.any?
      @error_message = @integration.errors.full_messages.first
      render 'stash_engine/user_admin/update_error' and return
    end
    render :close_modal
  end

  def permit_params
    params.require(:external_integration).permit(:id, :integration, :integrator_type, :integrator_id, :username, :password, details: [:site_name])
  end
end
