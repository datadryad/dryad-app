module StashEngine
  class Journal < ApplicationRecord
    validates :issn, uniqueness: true
    has_many :journal_roles
    has_many :users, through: :journal_roles
    belongs_to :sponsor, class_name: 'JournalOrganization', optional: true

    def will_pay?
      payment_plan_type == 'SUBSCRIPTION' ||
        payment_plan_type == 'PREPAID' ||
        payment_plan_type == 'DEFERRED'
    end

  end
end
