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
        enabled: enabled
      }
    end

    def name
      payer.name
    end

    def enabled
      payer.enabled
    end
  end
end
