# frozen_string_literal: true

# == Schema Information
#
# Table name: dcs_versions
#
#  id          :integer          not null, primary key
#  version     :string(191)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  resource_id :integer
#
# Indexes
#
#  index_dcs_versions_on_resource_id  (resource_id)
#
module StashDatacite
  class Version < ApplicationRecord
    self.table_name = 'dcs_versions'
    has_paper_trail

    belongs_to :resource, class_name: StashEngine::Resource.to_s
  end
end
