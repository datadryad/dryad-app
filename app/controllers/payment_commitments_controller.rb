class PaymentCommitmentsController < StashEngine::ApplicationController
  before_action :require_user_login
  before_action :set_sponsor

  def index
    authorize PaymentCommitment

    @sponsor_details = PayerDetailsService.new(@sponsor).details
  end

  def new
    authorize PaymentCommitment
    respond_to(&:js)
  end

  def create
    authorize PaymentCommitment

    error_message = PaymentCommitmentService.new(@sponsor).generate(
      create_params[:commitment_years].to_i,
      asf: create_params[:asf].to_f,
      asf_prepaid: create_params[:asf_prepaid].to_f,
      dpc_tier: create_params[:dpc_tier].to_i,
      start_date: create_params[:start_date] ? create_params[:start_date].to_date : Time.current,
      consortium_discount: create_params[:consortium_discount].to_i,
      covers_ldf: ActiveModel::Type::Boolean.new.cast(create_params[:covers_ldf]),
      ldf_size_limit: create_params[:ldf_size_limit].to_i,
      ldf: create_params[:ldf_commitment].to_i,
      include_year_0: ActiveModel::Type::Boolean.new.cast(create_params[:include_year_0])
    )

    if error_message.is_a?(String)
      flash.now[:alert] = error_message
    else
      @reload = true
    end
    respond_to(&:js)
  end

  def edit
    authorize PaymentCommitment

    @commitment = @sponsor.commitments.find(params[:id])
    respond_to(&:js)
  end

  def update
    authorize PaymentCommitment

    @commitment = @sponsor.commitments.find(params[:id])
    @commitment = PaymentCommitmentService.new(@sponsor).update(@commitment, edit_params)
    if @commitment.errors.any?
      flash.now[:alert] = @commitment.errors.full_messages.to_sentence
    else
      @reload = true
    end
    respond_to(&:js)
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
    params.permit(%i[commitment_years start_date include_year_0 asf consortium_discount dpc_tier
                     covers_ldf ldf_size_limit ldf_commitment asf_prepaid])
  end

  def edit_params
    params.require(:payment_commitment).permit(%i[start_date
                                                  period_discount consortium_discount
                                                  dpc_commitment dpc_carryover dpc_commitment_price
                                                  covers_ldf ldf_size_limit ldf_commitment ldf_carryover
                                                  asf asf_prepaid note])
  end
end
