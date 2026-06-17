module Payers
  class TenantAdapter < BaseAdapter

    def name
      payer.long_name
    end
  end
end
