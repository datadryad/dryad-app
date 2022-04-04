# frozen_string_literal: true

require 'stripe'

module StashEngine
  module StatusDashboard

    class StripeService < DependencyCheckerService

      def ping_dependency
        super
        # Check the status of the Stripe API via the stripe-ruby gem
        Stripe.api_key = StashEngine.app.payments.key

        obj = Stripe::Charge.list
        online = obj.is_a?(Stripe::ListObject)
        msg = "Stripe did not return the expected JSON format. Instead got: #{obj}" unless online
        record_status(online: online, message: msg)
        online
      rescue StandardError => e
        record_status(online: false, message: e.to_s)
        false
      end

    end

  end
end
