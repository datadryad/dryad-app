# overriding/monkeypatching some methods in geoblacklight that don't work for us
Geoblacklight::SolrDocument.class_eval do
  def bounding_box_as_wsen
    begin
      s = fetch(Settings.GEOMETRY_FIELD.to_sym)
    rescue KeyError => ex
      s = ''
    end
    if s =~ /^\s*ENVELOPE\(\s*([-\.\d]+)\s*,\s*([-\.\d]+)\s*,\s*([-\.\d]+)\s*,\s*([-\.\d]+)\s*\)\s*$/
      w = Regexp.last_match(1)
      s = Regexp.last_match(4)
      e = Regexp.last_match(2)
      n = Regexp.last_match(3)
      return "#{w} #{s} #{e} #{n}"
    else
      return s # as-is, not a WKT
    end
  end
end
