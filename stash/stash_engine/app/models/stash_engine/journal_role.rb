module StashEngine
  class JournalRole < ActiveRecord::Base
    belongs_to :journal
    belongs_to :user

    scope :admins, -> { where(role: 'admin') }
  end
end
