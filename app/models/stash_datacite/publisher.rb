# frozen_string_literal: true

# == Schema Information
#
# Table name: dcs_publishers
#
#  id          :integer          not null, primary key
#  publisher   :text(65535)
#  resource_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
module StashDatacite
  class Publisher < ApplicationRecord
    self.table_name = 'dcs_publishers'
    belongs_to :resource, class_name: StashEngine::Resource.to_s
  end
end
