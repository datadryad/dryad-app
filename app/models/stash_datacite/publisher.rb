# frozen_string_literal: true

# == Schema Information
#
# Table name: dcs_publishers
#
#  id                   :integer          not null, primary key
#  identifier_type      :string
#  publisher            :text(65535)
#  publisher_identifier :string(191)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  resource_id          :integer
#
# Indexes
#
#  index_dcs_publishers_on_resource_id  (resource_id)
#
module StashDatacite
  class Publisher < ApplicationRecord
    self.table_name = 'dcs_publishers'
    belongs_to :resource, class_name: StashEngine::Resource.to_s
  end
end
