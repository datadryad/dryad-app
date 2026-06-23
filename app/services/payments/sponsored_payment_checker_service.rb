module Payments
  class SponsoredPaymentCheckerService
    attr_reader :identifier

    def initialize(identifier, dry_run: true)
      Rails.logger.level = Logger::INFO
      @identifier = identifier
      @dry_run = dry_run
    end

    def self.check
      StashEngine::Identifier.order(id: :desc).each do |id|
        new(id).check_payment_log
      end
    end

    def check_payment_log
      pp identifier.id
      return unless identifier.sponsored?

      identifier.resources.order(:id).each do |res|
        Payments::ResourcePaymentCheckerService.new(res, dry_run: @dry_run).check_payment
      end
      true
    end
  end
end