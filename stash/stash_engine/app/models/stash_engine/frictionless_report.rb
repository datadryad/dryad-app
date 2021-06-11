module StashEngine
  class FrictionlessReport < ApplicationRecord
    belongs_to :generic_file, class_name: 'StashEngine::GenericFile'

    validates_presence_of :generic_file
    validates_presence_of :status

    enum status: { valid_: 'valid', invalid_: 'invalid', checking: 'checking', error: 'error' }
  end
end
