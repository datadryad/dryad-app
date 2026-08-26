class PaymentDetailsController < StashEngine::ApplicationController
  before_action :require_user_login
  before_action :set_sponsor, except: :identifier

  def sponsor
    authorize current_user, policy_class: PaymentDetailsPolicy

    @calculation_year = params[:year] || Date.today.year
    @identifiers = @service.identifiers
  end

  def edit
    respond_to(&:js)
  end

  def update
    @sponsor.update(edit_params)
    respond_to(&:js)
  end

  def identifier
    authorize current_user, policy_class: PaymentDetailsPolicy

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

  def set_sponsor
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
    @sponsor_details = PayerDetailsService.new(@sponsor).details
    @service = Payments::Sponsor.new(@sponsor, year: @calculation_year)
  end

  def edit_params
    params.permit(payment_configuration_attributes: %i[id payment_plan covers_ldf ldf_limit yearly_ldf_limit ldf_limit_notification _destroy])
  end

end
