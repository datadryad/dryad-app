class HiddensController < StashEngine::ApplicationController
  before_action :require_user_login
  before_action :authorize_file_actions, only: %i[file_validation fix_file_size validate recreate_digest]

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

  def sponsor_payment_details
    authorize current_user, policy_class: HiddenPagesPolicy

    @calculation_year = params[:year] || Date.today.year
    @sponsor = case params[:type]
               when 'StashEngine::Tenant'
                 StashEngine::Tenant.find(params[:id])
               when 'StashEngine::Journal'
                 StashEngine::Journal.find(params[:id])
               when 'StashEngine::JournalOrganization'
                 StashEngine::JournalOrganization.find(params[:id])
               when 'StashEngine::Funder'
                 StashEngine::Funder.find(params[:id])
               else
                 raise "Unknown sponsor type: #{params[:type]}"
               end
    @service = Payments::Sponsor.new(@sponsor, year: @calculation_year)

    @sponsor_details = PayerDetailsService.new(@sponsor).details

    @identifiers = @service.identifiers
  end

  def identifier_payment_details
    authorize current_user, policy_class: HiddenPagesPolicy

    @service = Payments::Identifier.new(params[:id])
    @identifier = @service.identifier
    @payment_sponsor = @service.payment_sponsor
    @limits_sponsor = @service.limits_sponsor
    @payment_sponsor_details = PayerDetailsService.new(@payment_sponsor).details
    @limits_sponsor_details = PayerDetailsService.new(@limits_sponsor).details

    @total_ldf = @service.total_ldf

    @price_calculation = ResourceFeeCalculatorService.new(@identifier.latest_resource).calculate({})
  end

  private

  def authorize_file_actions
    authorize(current_user, :file_validation?, policy_class: HiddenPagesPolicy)
  end
end
