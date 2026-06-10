class HiddensController < StashEngine::ApplicationController
  def file_validation
    authorize current_user, policy_class: HiddenPagesPolicy

    ids = params[:ids].split(',')
    @files = StashEngine::GenericFile.where(id: ids)
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
    @total_ldf = @service.total_ldf
    @total_dpc = @service.total_dpc
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
    # @total_dpc = @service.total_dpc
  end
end
