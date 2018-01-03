# frozen_string_literal: true

# TODO: delete
module StashDatacite
  class NameIdentifier < ActiveRecord::Base
    self.table_name = 'dcs_name_identifiers'
    has_many :contributors, class_name: 'Contributor'
  end
end
