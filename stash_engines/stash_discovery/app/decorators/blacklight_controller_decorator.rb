module Blacklight::Controller

  protected

  # a fix so it only outputs path so as not to change http/https for secure/insecure problems on page
  def search_facet_url options = {}
    opts = search_state.to_h.merge(action: "facet", only_path: true).merge(options).except(:page)
    url_for opts
  end

end