module StashEngine
  class FrictionlessReport < ApplicationRecord
    self.table_name = 'stash_engine_frictionless_reports'
    belongs_to :generic_file, class_name: 'StashEngine::GenericFile'

    validates_presence_of :generic_file
    validates_presence_of :status

    enum status: %w[issues noissues checking error].to_h { |i| [i.to_sym, i] }
  end
end
