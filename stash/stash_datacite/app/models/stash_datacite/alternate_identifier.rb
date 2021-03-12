# frozen_string_literal: true

module StashDatacite
  class AlternateIdentifier < ApplicationRecord
    self.table_name = 'dcs_alternate_identifiers'
    belongs_to :resource, class_name: StashEngine::Resource.to_s
  end
end
