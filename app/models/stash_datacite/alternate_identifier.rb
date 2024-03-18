# frozen_string_literal: true

# == Schema Information
#
# Table name: dcs_alternate_identifiers
#
#  id                        :integer          not null, primary key
#  alternate_identifier      :text(65535)
#  alternate_identifier_type :text(65535)
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  resource_id               :integer          not null
#
# Indexes
#
#  index_dcs_alternate_identifiers_on_resource_id  (resource_id)
#
module StashDatacite
  class AlternateIdentifier < ApplicationRecord
    self.table_name = 'dcs_alternate_identifiers'
    belongs_to :resource, class_name: StashEngine::Resource.to_s
  end
end
