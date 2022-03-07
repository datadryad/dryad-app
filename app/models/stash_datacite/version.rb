# frozen_string_literal: true

module StashDatacite
  class Version < ApplicationRecord
    self.table_name = 'dcs_versions'
    belongs_to :resource, class_name: StashEngine::Resource.to_s
  end
end
