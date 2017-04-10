module Blacklight::SearchContext

  # Hack to avoid reading from/writing to search table;
  # see also app/decorators/blacklight_controller_decorator.rb
  def find_or_initialize_search_session_from_params(params)
    params_copy = params.reject { |k,v| blacklisted_search_session_params.include?(k.to_sym) or v.blank? }
    return if params_copy.reject { |k,v| [:action, :controller].include? k.to_sym }.blank?
    OpenStruct.new(query_params: params_copy)
  end
end
