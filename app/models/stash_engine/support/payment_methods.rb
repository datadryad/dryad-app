require 'active_support/concern'

module StashEngine
  module Support
    module PaymentMethods
      extend ActiveSupport::Concern

      # Check if the user must pay for this identifier, or if payment is
      # otherwise covered - but send waivers to stripe
      def user_must_pay?
        !journal&.will_pay? && !institution_will_pay? && !funder_will_pay?
      end

      def payer
        return latest_resource&.tenant if institution_will_pay?
        return journal if journal&.will_pay?
        return funder_payment_info&.payer_funder if funder_will_pay?

        nil
      end

      def payer_2025?
        return false if old_payment_system

        current_payer = payer
        return true if current_payer.nil?

        return current_payer.payment_plan_type.to_s == '2025' if current_payer.is_a? StashEngine::Journal

        current_payer.payment_plan.to_s == '2025'
      end

      def sponsored
        payer.present?
      end

      def record_payment
        # once we have assigned payment to an entity, keep that entity
        # unless it was a journal that was removed
        clear_payment_for_changed_journal
        return if payment_type.present? && payment_type != 'unknown'

        if collection?
          self.payment_type = 'no_data'
          self.payment_id = nil
        elsif institution_will_pay?
          self.payment_id = latest_resource&.tenant&.id
          self.payment_type = "institution#{'-TIERED' if latest_resource&.tenant&.payment_plan == 'tiered'}"
        elsif journal&.will_pay?
          self.payment_type = "journal-#{journal.payment_plan_type}"
          self.payment_id = publication_issn
        elsif funder_will_pay?
          contrib = funder_payment_info
          self.payment_type = 'funder'
          self.payment_id = "funder:#{contrib.contributor_name}|award:#{contrib.award_number}"
        else
          self.payment_type = 'unknown'
          self.payment_id = nil
        end
        save
      end

      def institution_will_pay?
        tenant = latest_resource&.tenant
        return false unless tenant&.covers_dpc

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

      def clear_payment_for_changed_journal
        return unless payment_type.present?
        return unless payment_type.include?('journal') || journal&.will_pay?
        return if payment_id == journal&.single_issn

        self.payment_type = nil
        self.payment_id = nil
        save
        reload
      end
    end
  end
end
