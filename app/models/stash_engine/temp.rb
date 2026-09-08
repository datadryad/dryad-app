module StashEngine
  module Temp
    class Resource
      attr_accessor :id, :total_file_size, :tenant, :payment_type, :payment_id, :journal

      def hold_for_peer_review
        false
      end

      def identifier
        id = StashEngine::Temp::Identifier.new
        id.latest_resource = self
        id.payment_type = payment_type
        id.payment_id = payment_id
        id.journal = journal
        id
      end

      def contributors
        []
      end
    end

    class Identifier
      include StashEngine::PaymentMethods
      include StashEngine::Limits

      attr_accessor :latest_resource, :payment_type, :payment_id, :journal

      def last_invoiced_file_size
        nil
      end

      def old_payment_system
        false
      end

      def old_payment_system?
        false
      end

      def payments
        StashEngine::Temp::Payments.new
      end
    end

    class Payments
      def ppr_paid
        self
      end

      def paid
        self
      end

      def where
        self
      end

      def not(_resource_id)
        []
      end
    end
  end
end
