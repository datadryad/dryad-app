# frozen_string_literal: true

module StashDatacite
  class Subject < ActiveRecord::Base
    self.table_name = 'dcs_subjects'
    has_and_belongs_to_many :resources, class_name: StashEngine::Resource.to_s,
                                        through: 'StashDatacite::ResourceSubject'
  end
end
