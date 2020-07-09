# overriding/monkeypatching some methods in geoblacklight that don't work for us
Geoblacklight::SolrDocument.class_eval do
  def bounding_box_as_wsen
    s = fetch(Settings.GEOMETRY_FIELD.to_sym)
    return s unless s =~ /^\s*ENVELOPE\(\s*([-.\d]+)\s*,\s*([-.\d]+)\s*,\s*([-.\d]+)\s*,\s*([-.\d]+)\s*\)\s*$/

    w = Regexp.last_match(1)
    e = Regexp.last_match(2)
    n = Regexp.last_match(3)
    s = Regexp.last_match(4)
    "#{w} #{s} #{e} #{n}"
  rescue KeyError
    ''
  end
end
