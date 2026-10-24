class PaymentDetailsController < StashEngine::ApplicationController
  before_action :require_user_login
  before_action :set_sponsor, except: :identifier
  before_action :setup_paging, only: %i[sponsor dashboard]

  def sponsor
    authorize current_user, policy_class: PaymentDetailsPolicy
    @identifiers = @service.identifiers.page(@page).per(@page_size)
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

  def dashboard
    authorize @sponsor, policy_class: PaymentDetailsPolicy
    identifiers = @service.identifiers
    start = identifiers.publicly_viewable.pluck(:publication_date).min&.year || 2026
    @years = (start..Date.today.year).to_a
    identifiers = identifiers.send(params[:status]) if params[:status].present?
    @identifiers = identifiers.page(@page).per(@page_size)
    @limits_details = PayerDetailsService.new(@sponsor.limits_sponsor).details
  end

  private

  def set_sponsor
    @sponsor = case params[:type]
               when 'institution'
                 StashEngine::Tenant.find(params[:id])
               when 'journal'
                 StashEngine::Journal.find(params[:id])
               when 'publisher'
                 StashEngine::JournalOrganization.find(params[:id])
               when 'funder'
                 StashEngine::Funder.find(params[:id])
               else
                 raise "Unknown sponsor type: #{params[:type]}"
               end
    @calculation_year = params[:year] || Date.today.year
    @payment_plan = params[:plan] || '2025'
    @sponsor_details = PayerDetailsService.new(@sponsor).details
    @service = Payments::Sponsor.new(@sponsor, plan: @payment_plan)
    @limits_service = Payments::Sponsor.new(@sponsor.limits_sponsor, plan: @payment_plan)
  end

  def setup_paging
    @page = params[:page] || 1
    @page_size = 25 if params[:page_size].blank? || params[:page_size].to_i == 0
    @page_size ||= params[:page_size].to_i
  end

  def edit_params
    params.permit(payment_configuration_attributes: %i[id payment_plan covers_ldf ldf_limit yearly_ldf_limit ldf_limit_notification submitter_contact
                                                       _destroy])
  end

end
