# frozen_string_literal: true

# == Schema Information
#
# Table name: dcs_formats
#
#  id          :integer          not null, primary key
#  format      :text(65535)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  resource_id :integer          not null
#
# Indexes
#
#  index_dcs_formats_on_resource_id  (resource_id)
#
module StashDatacite
  class Format < ApplicationRecord
    self.table_name = 'dcs_formats'
    belongs_to :resource, class_name: StashEngine::Resource.to_s
  end
end
