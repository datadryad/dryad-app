# frozen_string_literal: true

module StashDatacite
  class Subject < ApplicationRecord
    self.table_name = 'dcs_subjects'
    has_and_belongs_to_many :resources, class_name: StashEngine::Resource.to_s,
                                        through: 'StashDatacite::ResourceSubject'

    # non_fos isn't a field of science
    # fos is a field of science, but only standard ones
    # permissive_fos is a field of science entry but could be good or a free-form one
    # bad_fos is a non-standard field entry that someone typed in
    scope :non_fos, -> { where("subject_scheme IS NULL OR subject_scheme NOT IN ('fos', 'bad_fos')") }
    scope :fos, -> { where("subject_scheme = 'fos'") }
    scope :permissive_fos, -> { where("subject_scheme IN ('fos', 'bad_fos')") }
    scope :bad_fos, -> { where("subject_scheme = 'bad_fos'") }
  end
end
