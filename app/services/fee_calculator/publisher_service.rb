module FeeCalculator
  class PublisherService < BaseService

    def service_fee_tiers
      PUBLISHER_SERVICE_FEE
    end
  end
end
