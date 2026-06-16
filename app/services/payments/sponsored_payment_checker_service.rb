class Payments::SponsoredPaymentCheckerService
  attr_reader :identifier
  def initialize(identifier)
    Rails.logger.level = Logger::INFO
    @identifier = identifier
  end

  def self.check
    StashEngine::Identifier.order(id: :desc).each do |id|
      new(id).check_payment_log
    end
  end

  def check_payment_log
    pp identifier
    if identifier.sponsored?
      identifier.resources.order(:id).each do |res|
        pp res.id
        pp '====================='
        pp 'needs_sponsored_payment_log?: ' + needs_sponsored_payment_log?(res).to_s
        # next if res.first_submitted_status.nil?

        pp status = res.first_submitted_status&.status
        pp date = res.first_submitted_status&.created_at
        if needs_sponsored_payment_log?(res) && res.sponsored_payment_log.nil?
          raise "needs paymentlog for res ID: #{res.id}"
        end
        # pp res.sponsored_payment_log

        # pp res.sponsored_payment_log
        # pp res.payment

        if status == 'peer_review'
          # if res.total_file_size >
        elsif status == 'queued'

        end
      end
      # aaa
    end
    true
  end

  private

  def create_log
    SponsoredPaymentsService.new(resource).log_payment
  end

  def needs_sponsored_payment_log?(resource)
    return false unless identifier.sponsored?
    return false unless resource.first_submitted_status&.status == 'queued'

    # TODO: check if it covered LDF at that time and limit was exceeded or not
    # PayersService.new(identifier.payer).sponsored_limits
    return true if PayersService.new(identifier.payer).sponsored_limits.covers_ldf

    sponsored_tier = ResourceFeeCalculatorService.new(resource).storage_fee_tier
    if sponsored_tier[:price] > 0
      prev_resource = resource.previous_resource
      return true if prev_resource.nil?

      prev_sponsored_tier = ResourceFeeCalculatorService.new(prev_resource).storage_fee_tier
      return sponsored_tier[:price] > prev_sponsored_tier[:price]
    end
    false
  end

  def needs_user_payment?(resource)
    return false unless identifier.sponsored?
    return false unless resource.first_submitted_status.status == 'queued'

    pp sponsored_tier = ResourceFeeCalculatorService.new(resource).storage_fee_tier
    # sponsored_price = sponsored_tier[:price]


    resource.first_submitted_status.status == 'queued' && resource.total_file_size > 100_000_000_000
  end
end