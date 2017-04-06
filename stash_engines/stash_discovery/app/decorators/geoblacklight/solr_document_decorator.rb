#overriding/monkeypatching some methods in geoblacklight that don't work for us
Geoblacklight::SolrDocument.class_eval do
  def bounding_box_as_wsen
    begin
      s = fetch(Settings.GEOMETRY_FIELD.to_sym)
    rescue KeyError => ex
      s = ''
    end
    if s =~ /^\s*ENVELOPE\(\s*([-\.\d]+)\s*,\s*([-\.\d]+)\s*,\s*([-\.\d]+)\s*,\s*([-\.\d]+)\s*\)\s*$/
      w, s, e, n = $1, $4, $2, $3
      return "#{w} #{s} #{e} #{n}"
    else
      return s # as-is, not a WKT
    end
  end
end