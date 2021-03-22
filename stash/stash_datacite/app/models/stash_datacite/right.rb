# frozen_string_literal: true

module StashDatacite
  class Right < ApplicationRecord
    self.table_name = 'dcs_rights'
    belongs_to :resource, class_name: StashEngine::Resource.to_s
  end
end
