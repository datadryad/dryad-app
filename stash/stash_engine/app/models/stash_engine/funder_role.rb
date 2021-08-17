module StashEngine
  class FunderRole < ApplicationRecord
    belongs_to :user

    scope :admins, -> { where(role: 'admin') }
  end
end
