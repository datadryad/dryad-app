# frozen_string_literal: true

module StashDatacite
  class Subject < ApplicationRecord
    self.table_name = 'dcs_subjects'
    has_and_belongs_to_many :resources, class_name: StashEngine::Resource.to_s,
                                        through: 'StashDatacite::ResourceSubject'

    # non_fos isn't a field of science
    # fos is a field of science, but only standard ones
    # permissive_fos is a field of science entry but could be good or a non-standard thing someone entered
    # bad_fos is a non-standard field of science entry that someone typed in and isn't really right.
    # TODO: We should add JS or other way to prevent these bad_fox and only allow good items in the list.

    scope :non_fos, -> { where("subject_scheme IS NULL OR subject_scheme NOT IN ('fos', 'bad_fos')") }
    scope :fos, -> { where("subject_scheme = 'fos'") }
    scope :permissive_fos, -> { where("subject_scheme IN ('fos', 'bad_fos')") }
    scope :bad_fos, -> { where("subject_scheme = 'bad_fos'") }
  end
end
