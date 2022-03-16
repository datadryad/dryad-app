# frozen_string_literal: true

# TODO: delete
module StashDatacite
  class NameIdentifier < ApplicationRecord
    self.table_name = 'dcs_name_identifiers'
    has_many :contributors, class_name: 'Contributor'
  end
end
