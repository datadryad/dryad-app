module Payers
  class BaseAdapter
    attr_reader :payer

    def initialize(payer)
      @payer = payer
    end

    def mappings
      {
        id: payer.id,
        name: name,
        contact: contact,
        enabled: enabled
      }
    end

    def name
      payer.name
    end

    def enabled
      payer.enabled
    end

    def contact
      payer.contact
    end
  end
end
