module StashDiscoveryHelper

  # override geoblacklight_icon since we don't always have one
  def geoblacklight_icon(name)
    name = '' if name.nil?
    super(name)
  end

end
