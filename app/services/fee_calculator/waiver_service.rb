module FeeCalculator
  class WaiverService < IndividualService

    private

    def storage_fee_label
      PRODUCT_NAME_MAPPER[:individual_storage_fee]
    end

    def add_individual_storage_fee
      super

      return if @sum.zero?
      return unless resource.identifier.payments.with_discount.paid.where.not(resource_id: resource.id).none?

      add_storage_discount_fee(:waiver_discount, FREE_STORAGE_SIZE)
      add_coupon(DISCOUNT_STORAGE_COUPON_ID)
    end

    def add_storage_fee_difference
      paid_for = FREE_STORAGE_SIZE
      paid_for = [paid_for, resource.identifier.last_invoiced_file_size.to_i].max

      super(paid_for)
    end
  end
end
