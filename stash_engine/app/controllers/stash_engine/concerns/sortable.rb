require 'active_support/concern'

# Provides support for enums stored as Strings in the DB
# This can be dropped in Rails 5
module StashEngine

  module Concerns

    module Sortable

      extend ActiveSupport::Concern

      included do

        def sort_column_definition(id, table, cols)
          SortableTable::SortColumnCustomDefinition.new(
            id,
            asc: cols.map { |c| "#{table}.#{c} asc" }.join(', '),
            desc: cols.map { |c| "#{table}.#{c} desc" }.join(', ')
          )
        end

      end

    end

  end

end
