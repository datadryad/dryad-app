# frozen_string_literal: true

module StashDatacite
  class Subject < ApplicationRecord
    self.table_name = 'dcs_subjects'
    has_and_belongs_to_many :resources, class_name: StashEngine::Resource.to_s,
                                        through: 'StashDatacite::ResourceSubject'

    scope :non_fos, -> { where("subject_scheme IS NULL OR subject_scheme <> 'fos'") }
  end
end
