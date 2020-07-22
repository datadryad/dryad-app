# Tools for supporting sortable tables in HTML views
module StashEngine
  module SortableTableHelper

    # Display an indicator on the column that is currently sorted
    def sort_display(col)
      return unless col == params[:sort]

      if params[:direction] == 'asc'
        'c-admin-table__sort-asc'
      else
        'c-admin-table__sort-desc'
      end
    end

    # Creates the clickable column heading for a sortable column
    def sortable_column_head(sort_field:, title:, params:)
      link_to(
        title,
        sort_link_url(sort_field),
        class: params[:sort] == sort_field ? "current #{params[:direction]}" : nil
      )
    end

    # Passthrough for HTTP parameters that allowed on pages with sortable tables
    def sortable_table_params
      params.permit(:q, :sort, :direction, :page, :page_size, :show_all,
                    :tenant, :curation_status, :publication_name, :all_advanced)
    end

    private

    # Returns the sort url for a given sort_field.
    def sort_link_url(sort_field)
      query_params = sortable_table_params
      query_params[:sort] = sort_field
      query_params[:direction] = if params[:sort] == sort_field
                                   switch_direction(params[:direction])
                                 else
                                   params[:direction] || 'asc'
                                 end

      base_url = url_for(query_params)
      Rails.logger.debug("##### query_params #{query_params}")
      Rails.logger.debug("##### base_url #{base_url}")
      sort_url = URI(base_url)
      sort_url.to_s
    end

    def switch_direction(dir)
      dir.downcase == 'asc' ? 'desc' : 'asc'
    end

  end
end
