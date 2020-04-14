module StashEngine
  class Journal < ActiveRecord::Base
    validates :issn, uniqueness: true

    def will_pay?
      payment_plan_type == 'SUBSCRIPTION' ||
        payment_plan_type == 'PREPAID' ||
        payment_plan_type == 'DEFERRED'
    end

  end
end
