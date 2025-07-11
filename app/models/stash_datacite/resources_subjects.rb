# frozen_string_literal: true

# == Schema Information
#
# Table name: dcs_subjects_stash_engine_resources
#
#  id          :integer          not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  resource_id :integer
#  subject_id  :integer
#
# Indexes
#
#  index_dcs_subjects_stash_engine_resources_on_resource_id  (resource_id)
#  index_dcs_subjects_stash_engine_resources_on_subject_id   (subject_id)
#
module StashDatacite
  class ResourcesSubjects < ApplicationRecord
    self.table_name = 'dcs_subjects_stash_engine_resources'
    has_paper_trail

    belongs_to :resource, class_name: 'StashEngine::Resource'
    belongs_to :subject, class_name: 'StashDatacite::Subject'

    validates :subject_id, presence: true, uniqueness: { scope: :resource_id }
  end
end
