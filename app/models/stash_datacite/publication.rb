# == Schema Information
#
# Table name: stash_engine_internal_data
#
#  id            :integer          not null, primary key
#  identifier_id :integer
#  data_type     :string(191)
#  value         :string(191)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
module StashDatacite
  class Publication < ApplicationRecord
    self.table_name = 'stash_engine_internal_data'
    belongs_to :stash_identifier, class_name: 'StashEngine::Identifier', foreign_key: 'identifier_id'
  end
end
