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
      my_str = ::Filesize.new(bytes, Filesize::SI).pretty
      if decimal_points == 2
        my_str.gsub('.00', '') # clean up decimal points if not needed, library doesn't have many formatting options
      else
        matches = my_str.match(/^([0-9\.]+) (\D+)/)
        number = matches[1].to_f
        units = matches[2]
        format("%0.#{decimal_points}f", number) + " #{units}"
      end
    end

    def unique_form_id(for_object)
      return "edit_#{simple_obj_name(for_object)}_#{for_object.id}" if for_object.id
      "new_#{simple_obj_name(for_object)}_#{SecureRandom.uuid}"
    end

    def simple_obj_name(obj)
      obj.class.to_s.split('::').last.downcase
    end
  end
end
