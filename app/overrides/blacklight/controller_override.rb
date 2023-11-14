# :nocov:
module Blacklight
  module Controller

    protected

    # a fix so it only outputs path so as not to change http/https for secure/insecure problems on page
    def search_facet_url(options = {})
      opts = search_state.to_h.merge(action: 'facet', only_path: true).merge(options).except(:page)
      url_for opts
    end

    # Hack to avoid reading from/writing to search table.
    # Note that we're basically disabling search history here; if
    # we want to re-enable it that will be some work.
    # See also:
    # - app/decorators/search_context_decorator.rb
    # - app/decorators/search_history_decorator.rb
    def searches_from_history
      []
    end
  end
end
# :nocov:
