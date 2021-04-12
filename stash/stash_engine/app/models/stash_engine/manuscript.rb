module StashEngine
  class Manuscript < ApplicationRecord
    belongs_to :journal
    belongs_to :identifier, optional: true

  end
end
