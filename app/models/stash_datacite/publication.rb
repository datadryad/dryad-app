# == Schema Information
#
# Table name: stash_engine_internal_data
#
#  id            :integer          not null, primary key
#  data_type     :string(191)
#  value         :string(191)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  identifier_id :integer
#
# Indexes
#
#  index_internal_data_on_identifier_and_data_type          (identifier_id,data_type)
#  index_stash_engine_internal_data_on_data_type_and_value  (data_type,value)
#  index_stash_engine_internal_data_on_identifier_id        (identifier_id)
#
module StashDatacite
  class Publication < ApplicationRecord
    self.table_name = 'stash_engine_internal_data'
    belongs_to :stash_identifier, class_name: 'StashEngine::Identifier', foreign_key: 'identifier_id'
  end
end
