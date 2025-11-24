require 'active_support/concern'

module StashEngine
  module Support
    module PaymentMethods
      extend ActiveSupport::Concern

      # Check if the user must pay for this identifier, or if payment is
      # otherwise covered - but send waivers to stripe
      def user_must_pay?
        return false if latest_resource.resource_type&.resource_type == 'collection'

        !journal&.will_pay? && !institution_will_pay? && !funder_will_pay?
      end

      def payer
        return funder_payment_info&.payer_funder if funder_will_pay?
        return latest_resource&.tenant if institution_will_pay?
        return journal if journal&.will_pay?

        nil
      end

      def payer_2025?
        return false if old_payment_system

        current_payer = payer
        return true if current_payer.nil?

        return current_payer.payment_configuration&.payment_plan.to_s == '2025' if current_payer.is_a? StashEngine::Journal

        current_payer.payment_configuration&.payment_plan.to_s == '2025'
      end

      def payment_needed?
        return false unless user_must_pay?
        return false if old_payment_system
        return false unless last_invoiced_file_size.blank? || last_invoiced_file_size.zero?

        true
      end

      def sponsored
        payer.present?
      end

      # rubocop:disable Metrics/AbcSize
      def record_payment
        # once we have assigned payment to an entity, keep that entity
        # unless a journal was removed or an institution added
        clear_payment_for_changed_sponsor
        return if payment_type.present? && payment_type != 'unknown'

        if collection?
          self.payment_type = 'no_data'
          self.payment_id = nil
        elsif funder_will_pay?
          contrib = funder_payment_info
          self.payment_type = 'funder'
          self.payment_id = "funder:#{contrib.contributor_name}|award:#{contrib.award_number}"
        elsif institution_will_pay?
          self.payment_id = latest_resource&.tenant&.id
          self.payment_type = "institution#{'-TIERED' if latest_resource&.tenant&.payment_configuration&.payment_plan == 'TIERED'}"
        elsif journal&.will_pay?
          self.payment_type = "journal-#{journal.payment_configuration.payment_plan}"
          self.payment_id = publication_issn
        elsif payments.count > 0
          self.payment_type = 'stripe'
          self.payment_id = payments.paid.last&.payment_id
        else
          self.payment_type = 'unknown'
          self.payment_id = nil
        end
        save
      end
      # rubocop:enable Metrics/AbcSize

      def institution_will_pay?
        tenant = latest_resource&.tenant
        return false unless tenant&.payment_configuration&.covers_dpc

        if tenant&.authentication&.strategy == 'author_match'
          # get all unique ror_id associations for all authors
          rors = latest_resource.authors.includes(:affiliations).map do |auth|
            auth&.affiliations&.map { |affil| affil&.ror_id }
          end.flatten.uniq
          return rors&.intersection(tenant&.ror_ids)&.present?
        end

        true
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
        payment_type == 'waiver'
      end

      private

      def clear_payment_for_changed_sponsor
        return unless payment_type.present?

        # remove existing payment for added funder
        if funder_will_pay?
          return if payment_type == 'funder' && payment_id.include?(funder_payment_info&.contributor_name)
        # remove existing payment for added institution
        elsif institution_will_pay?
          return if payment_type.include?('institution') && payment_id == latest_resource.tenant_id
        # remove payment if paying journal has changed or been removed
        else
          return unless payment_type.include?('journal') || journal&.will_pay?
          return if payment_id == journal&.single_issn
        end
        return if payments.paid.count > 0

        self.payment_type = nil
        self.payment_id = nil
        save
        reload
      end
    end
  end
end
