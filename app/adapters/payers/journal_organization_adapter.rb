module Payers
  class JournalOrganizationAdapter < BaseAdapter

    def enabled
      true
    end

    def contact
      payer.payment_configuration&.submitter_contact
    end

  end
end
