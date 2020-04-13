module StashEngine
  class Journal < ActiveRecord::Base
    validates :issn, uniqueness: true

  end
end
