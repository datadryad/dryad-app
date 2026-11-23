class PaymentCommitmentsController < StashEngine::ApplicationController
  before_action :require_user_login
  before_action :set_sponsor

  helper StashEngine::SortableTableHelper

  def new
    authorize PaymentCommitment
    respond_to(&:js)
  end

  def create
    authorize PaymentCommitment

    pp @sponsor
    pp generated = PaymentCommitmentService.new(@sponsor).generate(
      create_params[:commitment_years].to_i,
      asf: create_params[:asf].to_f,
      asf_prepaid: create_params[:asf_prepaid].to_f,
      dpc_tier: create_params[:dpc_tier].to_i,
      start_date: create_params[:start_date] ? create_params[:start_date].to_date : Time.current,
      consortium_discount: create_params[:consortium_discount].to_i,
      ldf_size_limit: create_params[:ldf_size_limit].to_i,
      ldf: create_params[:ldf_commitment].to_i,
      include_year_0: create_params[:include_year_0].presence
    )

    if generated == true
      flash[:notice] = 'Payment commitments generated successfully'
    else
      flash.now[:alert] = generated
    end
    respond_to(&:js)
  end

  def edit
    authorize PaymentCommitment
    respond_to(&:js)
  end

  def update
    authorize PaymentCommitment

    @sponsor.update(edit_params)
    respond_to(&:js)
  end

  def dashboard
    authorize PaymentCommitment

    @sponsor_details = PayerDetailsService.new(@sponsor).details
  end

  private

  def set_sponsor
    @sponsor = case params[:type]
               when 'institution'
                 StashEngine::Tenant.find(params[:sponsor_id])
               when 'journal'
                 StashEngine::Journal.find(params[:sponsor_id])
               when 'publisher'
                 StashEngine::JournalOrganization.find(params[:sponsor_id])
               when 'funder'
                 StashEngine::Funder.find(params[:sponsor_id])
               else
                 raise "Unknown sponsor type: #{params[:type]}"
               end
  end

  def create_params
    params.permit(%i[commitment_years start_date include_year_0 asf period_discount consortium_discount dpc_tier
                     ldf_size_limit ldf_commitment asf_prepaid])
  end

  def edit_params
    params.permit(%i[commitment_years start_date include_year_0 asf period_discount consortium_discount dpc_tier
                     ldf_size_limit ldf_commitment asf_prepaid])
  end
end
