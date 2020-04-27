module StashEngine
  class Journal < ActiveRecord::Base
    validates :issn, uniqueness: true
    has_many :journal_roles
    has_many :users, through: :journal_roles

    def will_pay?
      payment_plan_type == 'SUBSCRIPTION' ||
        payment_plan_type == 'PREPAID' ||
        payment_plan_type == 'DEFERRED'
    end

  end
end
