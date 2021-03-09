# frozen_string_literal: true

module StashDatacite
  class Publisher < ApplicationRecord
    self.table_name = 'dcs_publishers'
    belongs_to :resource, class_name: StashEngine::Resource.to_s
  end
end
