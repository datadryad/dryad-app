module StashEngine
  class RorOrg < ApplicationRecord
    validates :ror_id, uniqueness: true

  end
end
