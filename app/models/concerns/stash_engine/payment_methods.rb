require 'active_support/concern'
# rubocop:disable Metrics/ModuleLength
module StashEngine
  module PaymentMethods
    extend ActiveSupport::Concern

    # Check if the user must pay for this identifier, or if payment is
    # otherwise covered - but send waivers to stripe
    # if payer has a LDF limit set and it is reached:
    #  - institution should pay DPC
    #  - user pays LDF calculated as per institution
    # returns false if the user chooses to pay via invoice
    def user_must_pay?
      return false if old_system_valid_payer?
      return false if latest_resource.resource_type&.resource_type == 'collection'
      return false if waiver? && old_payment_system
      if sponsored?
        return PaymentLimitsService.new(latest_resource, payer).limits_exceeded?
      elsif waiver? && payer_2025?
        return false if ResourceFeeCalculatorService.new(latest_resource).calculate({})[:total].zero?
      end

      true
    end

    def user_paid_dpc?
      dpc_payment&.payment_type == 'ResourcePayment'
    end

    def payer
      return @payer if defined?(@payer)

      @payer = if funder_will_pay?
                 funder_payment_info&.payer_funder
               elsif institution_will_pay?
                 latest_resource&.tenant
               elsif journal_will_pay?
                 journal
               end
      @payer
    end

    def payer_2025?(current_payer = nil)
      return false if old_payment_system

      current_payer ||= payer
      return true if current_payer.nil?

      PayersService.new(current_payer).is_2025_payer?
    end

    def payer_name
      return 'Individual' if user_must_pay?

      payer_record = payer
      case payer_record.class.to_s
      when 'StashEngine::Journal'
        payer_record.title
      when 'StashEngine::Tenant'
        payer_record.long_name || payer_record.short_name
      when 'StashEngine::Funder'
        payer_record.name
      when 'StashDatacite::Contributor'
        payer_record.contributor_name
      end
    end

    def payment_needed?
      # if payment is via invoice, then user_must_pay returns false
      # since the user does not have to pay anything right now

      # should continue if we have an invoice OR user_must_pay
      should_continue = payments.last&.pay_with_invoice? || user_must_pay?
      return false unless should_continue
      return false if old_payment_system

      if payments.any?
        invoicer = Stash::Payments::StripeInvoicer.new(payments.last.resource)
        return !invoicer.invoice_paid? if invoicer.invoice_created?
      end

      return false unless last_invoiced_file_size.to_i.zero?

      true
    end

    def sponsored?
      payer.present?
    end

    # Payers that are:
    #  - not on 2025 plan
    def old_system_valid_payer?(current_payer: payer)
      current_payer = PayersService.new(current_payer).payment_sponsor
      return false if current_payer.blank?
      return false if payer_2025?(current_payer) || old_payment_system

      current_payer.payment_configuration&.valid_payer?
    end

    def record_payment
      # once we have assigned payment to an entity, keep that entity
      # unless a journal was removed or added an institution
      clear_payment_for_changed_sponsor
      return unless dpc_payment.nil?
      return if collection?

      if payer.present?
        payer_sponsor = PayersService.new(payer).payment_sponsor
        payment_plan = payer_sponsor&.payment_configuration&.payment_plan

        update(old_payment_system: false)
        PaymentRecord.create(payment: payer, payment_plan: payment_plan, resource: latest_resource, identifier: identifier)

      elsif payments.paid.where(ppr_fee_paid: false).any? && !old_system_valid_payer?
        payment = payments.paid.last
        PaymentRecord.find_or_create_by(payment: payment, resource: payment.resource, identifier: identifier, fee_type: :dpc, active: true)
      end
    end

    def recorded_payer
      return nil if dpc_payment.nil? || waiver?
      return latest_resource.submitter if user_paid_dpc?

      dpc_payment.payment
    end

    def display_payer
      sponsor = recorded_payer if published? && recorded_payer.present?
      sponsor ||= payer
      sponsor = nil if sponsor.is_a?(StashEngine::User)
      sponsor.present? ? PayerDetailsService.new(sponsor).details.to_h : {}
    end

    def institution_will_pay?
      tenant = latest_resource&.tenant

      # do not remove recorded institution sponsor due to sponsorship change
      return true if dpc_payment&.payment == tenant
      return false unless PayersService.new(tenant).payment_sponsor&.payment_configuration&.covers_dpc?

      if tenant&.authentication&.strategy == 'author_match'
        # get all unique ror_id associations for all authors
        rors = latest_resource.authors.includes(:affiliations).map do |auth|
          auth&.affiliations&.map { |affil| affil&.ror_id }
        end.flatten.uniq
        return rors&.intersection(tenant&.ror_ids)&.present?
      end

      true
    end

    def journal_will_pay?
      return false unless journal

      journal.will_pay?
    end

    def funder_will_pay?
      return false if latest_resource.nil?

      latest_resource.contributors.each { |contrib| return true if contrib.payment_exempted? }

      false
    end

    def funder_payment_info
      return nil unless funder_will_pay?

      latest_resource.contributors.each { |contrib| return contrib if contrib.payment_exempted? }
    end

    def waiver?
      dpc_payment&.payment_type == 'StashEngine::Waiver'
    end

    # "old_" methods for reporting purposes. Can be removed if we adjust reporting!

    def old_payment_type
      return nil unless dpc_payment

      type = if user_paid_dpc?
               'stripe'
             else
               dpc_payment.payment_type.parameterize.sub('stashengine-', '').sub('tenant', 'institution')
             end
      type += "-#{dpc_payment.payment_plan}" if dpc_payment&.payment_plan
      type
    end

    def old_payment_id
      return nil unless dpc_payment

      case dpc_payment.payment_type
      when 'StashEngine::Waiver'
        nil
      when 'ResourcePayment'
        dpc_payment.payment.payment_intent.presence || dpc_payment.payment.invoice_id
      when 'StashEngine::Funder'
        "funder:#{dpc_payment.payment.name}"
      when 'StashEngine::Tenant'
        dpc_payment.payment.id
      when 'StashEngine::Journal'
        dpc_payment.payment.single_issn
      end
    end

    private

    def clear_payment_for_changed_sponsor
      return if dpc_payment.nil?
      return if user_paid_dpc?

      if funder_will_pay?
        # remove existing payment for added funder
        return if dpc_payment.payment == funder_payment_info&.payer_funder
      elsif institution_will_pay?
        # remove existing payment for added institution
        return if dpc_payment.payment == latest_resource.tenant
      else
        # remove payment if paying journal has changed or been removed
        return unless dpc_payment.payment_type == 'StashEngine::Journal' || journal_will_pay?
        return if dpc_payment.payment == journal
      end

      dpc_payment.update(active: false)
      sponsored_payment_logs.each(&:destroy)
      self.last_invoiced_file_size = 0
      save
      reload
    end
  end
end
# rubocop:enable Metrics/ModuleLength
