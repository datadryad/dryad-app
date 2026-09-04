module Payers
  class TenantAdapter < BaseAdapter

    def name
      payer.long_name
    end

    def contact
      payer.payment_sponsor&.payment_configuration&.submitter_contact
    end

  end
end
