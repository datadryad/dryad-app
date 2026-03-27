module FeeCalculator
  class IndividualService < BaseService
    def call
      verify_new_payment_system
      verify_max_storage_size if resource

      add_individual_storage_fee
      add_storage_fee_label
      add_ppr_fee(PPR_FEE)
      add_invoice_fee
      add_ppr_discount
      @sum_options.merge(total: @sum)
    end

    def storage_fee_tiers
      INDIVIDUAL_ESTIMATED_FILES_SIZE
    end

    private

    def storage_fee_label
      PRODUCT_NAME_MAPPER[:individual_storage_fee]
    end

    def add_individual_storage_fee
      if resource.present?
        if resource.identifier.last_invoiced_file_size.to_i.zero?
          add_dataset_storage_fee
        else
          add_storage_fee_difference
        end
      else
        add_storage_fee
      end
    end

    def add_ppr_discount
      return if @sum.zero?
      return unless resource.present?
      return unless resource.identifier.payments.ppr_paid.paid.where.not(resource_id: resource.id).first&.amount == PPR_FEE
      return unless resource.identifier.payments.with_discount.paid.where.not(resource_id: resource.id).count.zero?

      add_fee_to_total(:ppr_discount, -PPR_FEE)
      add_coupon(PPR_COUPON_ID)
    end
  end
end
