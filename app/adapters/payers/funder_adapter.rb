module Payers
  class FunderAdapter < BaseAdapter
    def contact
      payer.payment_configuration.submitter_contact
    end
  end
end
