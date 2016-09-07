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
      ::Filesize.new(bytes, Filesize::SI).pretty
    end
  end
end
