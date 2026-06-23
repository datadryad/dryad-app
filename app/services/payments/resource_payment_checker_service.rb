module Payments
  class ResourcePaymentCheckerService
    attr_reader :resource, :identifier, :payer, :sponsored_log

    def initialize(resource, dry_run: true)
      @resource = resource
      @dry_run = dry_run
      @sponsored_log = resource.sponsored_payment_log

      @identifier = resource.identifier
      @payer = @identifier.payer
      @status = resource.first_submitted_status&.status
      @resource_fees_service = ResourceFeeCalculatorService.new(resource)
    end

    def check_payment
      pp '====================='
      pp resource.id
      pp @status
      return unless identifier.sponsored?

      if needs_sponsored_payment_log?
        pp "1111 sponsored_amount: #{sponsored_log&.ldf} - logged_amount: #{logged_amount}"

        if sponsored_log.nil?
          create_log

        elsif sponsored_log.ldf == sponsored_amount
          return

        elsif sponsored_log.ldf != sponsored_amount && !sponsored_log.ldf.zero?
          update_log
        elsif sponsored_log.ldf.zero?
          delete_log
        elsif sponsored_log && sponsored_log.ldf.zero?
          delete_log
        end

        # if @status == 'peer_review'
        #   # if res.total_file_size >
        # elsif @status == 'queue
        # d'
        #
        # end
      end
    end

    private

    def create_log
      # pp "**************"
      pp "CREATING log for #{sponsored_amount} for resource: #{resource.id} - #{resource.identifier_id}"
      return if @dry_run

      SponsoredPaymentLog.create(
        resource: resource,
        payer: payer,
        ldf: sponsored_amount,
        sponsor_id: PayersService.new(payer).payment_sponsor&.id
      )
    end

    def update_log
      pp "UPDATING log #{sponsored_log.id} from #{sponsored_log.ldf} to #{sponsored_amount} for resource: #{resource.id} - #{resource.identifier_id}"
      return if @dry_run

      sponsored_log.update(
        payer: payer,
        ldf: sponsored_amount,
        sponsor_id: PayersService.new(payer).payment_sponsor&.id
      )
    end

    def delete_log
      pp "DELETING log #{sponsored_log.id} with #{sponsored_log.ldf} for resource: #{resource.id} - #{resource.identifier_id}"
      return if @dry_run

      sponsored_log.destroy
    end

    def needs_sponsored_payment_log?
      # Dataset is not sponsored
      return false unless identifier.sponsored?
      # Resource is not in `queued` yet
      return false unless @status.present?

      # TODO: check if it covered LDF at that time and limit was exceeded or not
      limits_config = PayersService.new(identifier.payer).sponsored_limits
      # payer does not cover LDF
      return false unless limits_config&.covers_ldf

      resource_tier = fee_calculator_service.storage_fee_tier
      if resource_tier[:price] > 0
        # Sponsored amount already logged on previous resource
        pp "2222 sponsored_amount: #{sponsored_log&.ldf} - logged_amount: #{logged_amount}"
        return logged_amount != sponsored_amount && !sponsored_amount.zero?
      end
      false
    end

    def fee_calculator_service
      @fee_calculator_service ||= ResourceFeeCalculatorService.new(resource)
    end

    def sponsored_amount
      sponsored_tier = fee_calculator_service.sponsored_tier
      resource_tier = fee_calculator_service.storage_fee_tier

      [sponsored_tier[:price], resource_tier[:price]].min - logged_amount
    end

    def logged_amount
      SponsoredPaymentLog.where(resource_id: resource.previous_resources.pluck(:id)).sum(:ldf)
    end

    def needs_user_payment?(resource)
      return false unless identifier.sponsored?
      return false unless resource.first_submitted_status.status == 'queued'

      pp sponsored_tier = ResourceFeeCalculatorService.new(resource).storage_fee_tier
      # sponsored_price = sponsored_tier[:price]

      resource.first_submitted_status.status == 'queued' && resource.total_file_size > 100_000_000_000
    end
  end
end