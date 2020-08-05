module StashEngine
  class JournalRole < ApplicationRecord
    belongs_to :journal
    belongs_to :user

    scope :admins, -> { where(role: 'admin') }
  end
end
