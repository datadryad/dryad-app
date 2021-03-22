# frozen_string_literal: true

module StashDatacite
  class ResourcesSubjects < ApplicationRecord
    self.table_name = 'dcs_subjects_stash_engine_resources'
    belongs_to :resource, class_name: StashEngine::Resource.to_s
    has_many :subjects
  end
end
