# frozen_string_literal: true

# == Schema Information
#
# Table name: dcs_sizes
#
#  id          :integer          not null, primary key
#  size        :text(65535)
#  resource_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
module StashDatacite
  class Size < ApplicationRecord
    self.table_name = 'dcs_sizes'
    belongs_to :resource, class_name: StashEngine::Resource.to_s
  end
end
