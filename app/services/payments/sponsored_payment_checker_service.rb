module Payments
  class SponsoredPaymentCheckerService
    attr_reader :identifier

    def initialize(identifier, dry_run: true, logging: false)
      Rails.logger.level = Logger::INFO
      @identifier = identifier
      @dry_run = dry_run
      @logging = logging || dry_run
    end

    def self.check
      StashEngine::Identifier.order(id: :desc).each do |id|
        new(id).check_payment_log
      end
    end

    def check_payment_log
      pp "identifier #{identifier.id}" if @logging
      return unless identifier.sponsored?

      return if identifier.latest_resource.
        # TODO: skip if sponsored LDF sum is correct and identifier last_invoiced_file_size is correct

        identifier.resources.order(:id).each do |res|
        Payments::ResourcePaymentCheckerService.new(res, dry_run: @dry_run, logging: @logging).check_payment
      end

      pp "DONE #{identifier.id} - #{identifier.last_invoiced_file_size}, #{identifier.latest_resource.total_file_size}"
      true
    end
  end
end
