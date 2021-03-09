# frozen_string_literal: true

module StashDatacite
  class Language < ApplicationRecord
    self.table_name = 'dcs_languages'
    belongs_to :resource, class_name: StashEngine::Resource.to_s
  end
end
