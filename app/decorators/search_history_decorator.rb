# Note that we're basically disabling search history here; if
# we want to re-enable it that will be some work
module Blacklight::SearchHistory
  # Hack to avoid reading from/writing to search table;
  # see also app/decorators/search_context_decorator.rb
  def searches_from_history
    []
  end
end
