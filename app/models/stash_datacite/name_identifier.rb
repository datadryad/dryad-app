# frozen_string_literal: true

# == Schema Information
#
# Table name: dcs_name_identifiers
#
#  id                     :integer          not null, primary key
#  name_identifier        :text(65535)
#  name_identifier_scheme :text(65535)
#  scheme_URI             :text(65535)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_dcs_name_identifiers_on_name_identifier  (name_identifier)
#
module StashDatacite
  class NameIdentifier < ApplicationRecord
    self.table_name = 'dcs_name_identifiers'
    has_many :contributors, class_name: 'Contributor'
  end
end
