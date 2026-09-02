module Payers
  class JournalAdapter < BaseAdapter

    def name
      payer.title
    end

    def enabled
      true
    end

    def contact
      payer.limits_sponsor&.payment_configuration&.submitter_contact
    end

  end
end
