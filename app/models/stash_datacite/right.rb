# frozen_string_literal: true

# == Schema Information
#
# Table name: dcs_rights
#
#  id          :integer          not null, primary key
#  rights      :text(65535)
#  rights_uri  :text(65535)
#  resource_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
module StashDatacite
  class Right < ApplicationRecord
    self.table_name = 'dcs_rights'
    belongs_to :resource, class_name: StashEngine::Resource.to_s
  end
end
