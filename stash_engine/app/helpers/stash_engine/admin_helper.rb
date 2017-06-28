module StashEngine
  module AdminHelper

    def sort_display(col, sort_col)
      return unless col == sort_col.column
      if sort_col.direction == 'asc'
        'c-admin-table__sort-asc'
      else
        'c-admin-table__sort-desc'
      end
    end
  end
end
