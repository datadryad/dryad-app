module FeeCalculator
  class InstitutionService < BaseService

    def service_fee_tiers
      return LOW_MIDDLE_SERVICE_FEE if options[:low_middle_income_country]

      NORMAL_SERVICE_FEE
    end
  end
end
