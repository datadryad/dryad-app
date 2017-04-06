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

    def filesize(bytes)
      return '' if bytes.nil?
      return "#{bytes} B" if bytes < 1000
      my_str = ::Filesize.new(bytes, Filesize::SI).pretty
      my_str.gsub('.00', '') # clean up decimal points if not needed, library doesn't have many formatting options
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
