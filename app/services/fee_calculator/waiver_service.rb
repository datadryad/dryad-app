module FeeCalculator
  class WaiverService < BaseService

    def call
      verify_new_payment_system
      verify_max_storage_size
      add_zero_fee(:storage_fee)
      add_storage_fee_label
      @sum_options.merge(total: @sum)
    end

    private

    def storage_fee_label
      PRODUCT_NAME_MAPPER[:individual_storage_fee]
    end
  end
end
