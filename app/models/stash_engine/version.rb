module StashEngine
  class Version < ActiveRecord::Base
    belongs_to :resource
  end
end
