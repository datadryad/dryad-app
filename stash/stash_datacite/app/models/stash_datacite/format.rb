# frozen_string_literal: true

module StashDatacite
  class Format < ApplicationRecord
    self.table_name = 'dcs_formats'
    belongs_to :resource, class_name: StashEngine::Resource.to_s
  end
end
