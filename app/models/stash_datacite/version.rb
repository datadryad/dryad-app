# frozen_string_literal: true

# == Schema Information
#
# Table name: dcs_versions
#
#  id          :integer          not null, primary key
#  version     :string(191)
#  resource_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
module StashDatacite
  class Version < ApplicationRecord
    self.table_name = 'dcs_versions'
    belongs_to :resource, class_name: StashEngine::Resource.to_s
  end
end
