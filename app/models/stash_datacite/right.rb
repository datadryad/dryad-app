# frozen_string_literal: true

# == Schema Information
#
# Table name: dcs_rights
#
#  id          :integer          not null, primary key
#  rights      :text(65535)
#  rights_uri  :text(65535)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  resource_id :integer
#
# Indexes
#
#  index_dcs_rights_on_resource_id  (resource_id)
#
module StashDatacite
  class Right < ApplicationRecord
    self.table_name = 'dcs_rights'
    belongs_to :resource, class_name: StashEngine::Resource.to_s
  end
end
