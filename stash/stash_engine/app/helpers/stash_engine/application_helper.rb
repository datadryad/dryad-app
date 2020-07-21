require 'filesize'

module StashEngine
  module ApplicationHelper
    # displays log in/out based on session state, temporary for now
    # :nocov:
    def log_in_out
      if session[:user_id].blank?
        link_to 'log in', stash_url_helpers.tenants_path
      else
        link_to 'log out', stash_url_helpers.sessions_destroy_path
      end
    end
    # :nocov:

    # no decimal removes the after decimal bits
    def filesize(bytes, decimal_points = 2)
      return '' if bytes.nil?
      return "#{bytes} B" if bytes < 1000

      size_str = ::Filesize.new(bytes, Filesize::SI).pretty
      return size_str.gsub('.00', '') if decimal_points == 2

      matches = size_str.match(/^([0-9.]+) (\D+)/)
      number = matches[1].to_f
      units = matches[2]
      format("%0.#{decimal_points}f", number) + " #{units}"
    end

    def unique_form_id(for_object)
      return "edit_#{simple_obj_name(for_object)}_#{for_object.id}" if for_object.id

      "new_#{simple_obj_name(for_object)}_#{SecureRandom.uuid}"
    end

    def simple_obj_name(obj)
      obj.class.to_s.split('::').last.downcase
    end

    ##### TODO -- move the below methods into a SortableTableHelper

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
    def sort_by(sort_field, title: nil, current_column: nil)
      link_to(
        title,
        sort_link_url(sort_field),
        class: params[:sort] == sort_field ? "current #{params[:direction]}" : nil
      )
    end

    # Returns the sort url for a given sort_field.
    def sort_link_url(sort_field)
      query_params = {}
      query_params[:sort] = sort_field
      query_params[:direction] = if params[:sort] == sort_field
                                   switch_direction(params[:direction])
                                 else
                                   params[:direction] || 'asc'
                                 end
      url_params = query_params.merge(
        controller: params[:controller],
        action: params[:action],
        page: params[:page]
      )
      base_url = url_for(url_params)
      Rails.logger.debug("##### query_params #{query_params}")
      Rails.logger.debug("##### url_params #{url_params}")
      Rails.logger.debug("##### base_url #{base_url}")
      sort_url = URI(base_url)
      sort_url.to_s
    end

    def switch_direction(dir)
      dir.downcase == 'asc' ? 'desc' : 'asc'
    end

  end
end
