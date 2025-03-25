module FeeCalculator
  class InstitutionService < BaseService

    NORMAL_SERVICE_FEE = [
      { tier: 1, range: 0..99_000_000, price: 5_000 },
      { tier: 2, range: 100_000_001..250_000_000, price: 10_000 },
      { tier: 3, range: 250_000_001..500_000_000, price: 20_000 },
      { tier: 4, range: 500_000_001..750_000_000, price: 30_000 },
      { tier: 5, range: 750_000_001..1_000_000_000, price: 40_000 },
      { tier: 6, range: 1_000_000_001..Float::INFINITY, price: 50_000 },
    ].freeze

    LOW_MIDDLE_SERVICE_FEE = [
      { tier: 1, range: 0..5_000_000, price: 1_000 },
      { tier: 2, range: 5_000_001..25_000_000, price: 1_500 },
      { tier: 3, range: 25_000_001..50_000_000, price: 2_500 },
      { tier: 4, range: 50_000_001..100_000_000, price: 5_000 },
      { tier: 5, range: 100_000_001..Float::INFINITY, price: 7_500 },

    ].freeze

    ESTIMATED_DATASETS = [
      { tier: 1, range: 0..5, price: 0 },
      { tier: 2, range: 6..15, price: 1_650 },
      { tier: 3, range: 16..25, price: 2_700 },
      { tier: 4, range: 26..50, price: 5_350 },
      { tier: 5, range: 51..75, price: 7_950 },
      { tier: 6, range: 76..100, price: 10_500 },
      { tier: 7, range: 101..150, price: 15_600 },
      { tier: 8, range: 151..200, price: 20_500 },
      { tier: 9, range: 201..250, price: 25_500 },
      { tier: 10, range: 251..300, price: 30_250 },
      { tier: 11, range: 301..350, price: 35_000 },
      { tier: 12, range: 351..400, price: 39_500 },
      { tier: 13, range: 401..450, price: 44_000 },
      { tier: 14, range: 451..500, price: 48_750 },
      { tier: 15, range: 501..550, price: 53_500 },
      { tier: 16, range: 551..600, price: 58_250 }
    ].freeze

    # in GB so we need to "ceil" values to GB
    ESTIMATED_FILES_SIZE = [
      { tier: 1, range: 10_000_000_000..50_000_000_000, price: 259 },
      { tier: 2, range: 50_000_000_001..100_000_000_000, price: 464 },
      { tier: 3, range: 100_000_000_001..250_000_000_000, price: 1_123 },
      { tier: 4, range: 250_000_000_001..500_000_000_000, price: 2_153 },
      { tier: 5, range: 500_000_000_001..1_000_000_000_000, price: 4_347 },
      { tier: 6, range: 1_000_000_000_001..2_000_000_000_000, price: 8_809 },
    ]

    def call
      if for_dataset
        add_zero_fee(:service_fee)
        add_zero_fee(:dpc)
        add_storage_fee
      else
        add_service_fee
        add_dpc_fee
      end
      @sum_options.merge(total: @sum)
    end

    private

    def add_dpc_fee
      add_fee_by_tier(ESTIMATED_DATASETS, :dpc)
    end

    def add_service_fee
      add_fee_by_tier(service_fee_rates, :service_fee)
    end

    def add_storage_fee
      add_fee_by_range(ESTIMATED_FILES_SIZE, :storage_size)
    end

    def service_fee_rates
      return LOW_MIDDLE_SERVICE_FEE if options[:low_middle_income_country]==true
      NORMAL_SERVICE_FEE
    end
  end
end



