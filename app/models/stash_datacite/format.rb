# frozen_string_literal: true

# == Schema Information
#
# Table name: dcs_formats
#
#  id          :integer          not null, primary key
#  format      :text(65535)
#  resource_id :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
module StashDatacite
  class Format < ApplicationRecord
    self.table_name = 'dcs_formats'
    belongs_to :resource, class_name: StashEngine::Resource.to_s
  end
end
