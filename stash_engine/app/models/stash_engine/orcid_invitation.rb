module StashEngine
  class OrcidInvitation < ActiveRecord::Base
    belongs_to :identifier, class_name: 'StashEngine::Identifier'

  end
end
