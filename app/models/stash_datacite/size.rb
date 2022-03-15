# frozen_string_literal: true

module StashDatacite
  class Size < ApplicationRecord
    self.table_name = 'dcs_sizes'
    belongs_to :resource, class_name: StashEngine::Resource.to_s
  end
end
