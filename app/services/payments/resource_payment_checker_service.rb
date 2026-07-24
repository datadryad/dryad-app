module Payments
  class ResourcePaymentCheckerService
    attr_reader :resource, :identifier, :payer, :sponsored_log

    def initialize(resource, dry_run: true, logging: false)
      @resource = resource
      @dry_run = dry_run
      @logging = logging || dry_run
      @sponsored_log = resource.sponsored_payment_log

      @identifier = resource.identifier
      @payer = @identifier.payer
      @status = resource.first_submitted_status&.status
      @resource_fees_service = ResourceFeeCalculatorService.new(resource)
    end

    def check_payment
      if @logging
        pp '==================================================================================================================================================='
        pp resource.id
        pp @status
      end
      return unless identifier.sponsored?

      paid_before = delete_larger_file_size_logs
      amount = @resource_fees_service.ldf_sponsored_amount(paid_storage_size: paid_before)
      needs_log = needs_sponsored_payment_log?

      if @logging
        pp "size: #{paid_before} -> #{resource.total_file_size}"
        pp "PDF amount: #{amount}"
        pp "needs log: #{needs_log}"
      end

      if needs_log
        update_identifier_files_size(resource)

        if amount <= 0
          delete_log(resource)
          return
        end

        if sponsored_log.nil?
          create_log
        elsif sponsored_log.ldf != amount
          update_log
        end

        # if @status == 'peer_review'
        #   # if res.total_file_size >
        # elsif @status == 'queue
        # d'
        #
        # end
      else
        resource.sponsored_payment_log&.destroy
      end
    end

    private

    def create_log
      return if sponsored_log&.ldf == sponsored_amount

      pp "CREATING log for #{sponsored_amount} for resource: #{resource.id} - #{resource.identifier_id}" if @logging
      return if @dry_run

      # update_identifier_files_size(resource)
      SponsoredPaymentLog.create!(
        resource: resource,
        payer: payer,
        ldf: sponsored_amount,
        sponsor_id: PayersService.new(payer).payment_sponsor&.id
      )
    end

    def update_log
      if @logging
        pp "UPDATING log #{sponsored_log.id} from #{sponsored_log.ldf} to #{sponsored_amount} for resource: #{resource.id} - #{resource.identifier_id}"
      end
      return if @dry_run

      # update_identifier_files_size(resource)
      sponsored_log.update(
        payer: payer,
        ldf: sponsored_amount,
        sponsor_id: PayersService.new(payer).payment_sponsor&.id
      )
    end

    def delete_log(res)
      return if res.sponsored_payment_log.nil?

      if @logging
        pp "DELETING log #{res.sponsored_payment_log.id} with #{res.sponsored_payment_log.ldf} for resource: #{resource.id} - #{resource.identifier_id}"
      end
      return if @dry_run

      # update_identifier_files_size(resource)

      res.sponsored_payment_log.destroy
    end

    def update_identifier_files_size(resource)
      return if @dry_run
      return if @status == 'peer_review'
      pp "Updating identifier #{identifier.id} with #{resource.total_file_size}" if @logging

      identifier.update(last_invoiced_file_size: resource.total_file_size)
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

      # new tier is over the sponsored tier per resource
      resource_tier = fee_calculator_service.storage_fee_tier
      return true if limits_config.ldf_limit.blank? || limits_config.ldf_limit >= resource_tier[:tier]

      if resource_tier[:price] > 0 && resource_tier[:price] >= sponsored_amount
        # Sponsored amount already logged on previous resource
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

    # def needs_user_payment?(resource)
    #   return false unless identifier.sponsored?
    #   return false unless resource.first_submitted_status.status == 'queued'
    #
    #   sponsored_tier = fee_calculator_service.storage_fee_tier
    #   # sponsored_price = sponsored_tier[:price]
    #
    #   resource.first_submitted_status.status == 'queued' && resource.total_file_size > 100_000_000_000
    # end

    def delete_larger_file_size_logs
      return 0 if resource.previous_resources.map(&:sponsored_payment_log).compact.none?

      paid_before = identifier.last_invoiced_file_size.to_i

      if paid_before > resource.total_file_size
        new_tier = @resource_fees_service.storage_fee_tier
        resource.previous_resources.each do |res|
          # stop at last sponsored resource
          return res.total_file_size if res.status_published?

          res_tier = ResourceFeeCalculatorService.new(res).storage_fee_tier
          if new_tier[:price] < res_tier[:price]
            if res.sponsored_payment_log
              pp "deleting log for res #{res.id} and amount #{res.sponsored_payment_log&.ldf}"
              delete_log(res)
            end
          else
            paid_before = res.total_file_size
            break
          end
        end
      end

      paid_before
    end
  end
end
