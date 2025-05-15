module FeeCalculator
  class WaiverService < IndividualService

    DISCOUNT_STORAGE_COUPON_ID = 'FEE_WAIVER_2025'.freeze
    FREE_STORAGE_SIZE = 10_000_000_000

    private

    def storage_fee_label
      PRODUCT_NAME_MAPPER[:individual_storage_fee]
    end

    def add_individual_storage_fee
      paid_for = FREE_STORAGE_SIZE
      paid_for = [paid_for, resource.identifier.previous_invoiced_file_size.to_i].max if resource

      add_storage_fee_difference(paid_for)
      return unless resource
      return unless resource.total_file_size.to_i > paid_for

      return unless resource.identifier.payments.with_discount.count.zero?

      add_storage_discount_fee(:waiver_discount, FREE_STORAGE_SIZE)
      add_coupon(DISCOUNT_STORAGE_COUPON_ID)
    end
  end
end
