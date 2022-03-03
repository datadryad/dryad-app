module Blacklight
  module SearchHistory
    # Hack to avoid reading from/writing to search table.
    # Note that we're basically disabling search history here; if
    # we want to re-enable it that will be some work.
    # See also:
    # - app/decorators/blacklight_controller_decorator.rb
    # - app/decorators/search_context_decorator.rb
    def searches_from_history
      []
    end
  end
end
