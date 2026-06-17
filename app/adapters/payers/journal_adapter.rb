module Payers
  class JournalAdapter < BaseAdapter

    def name
      payer.title
    end

    def enabled
      true
    end
  end
end
