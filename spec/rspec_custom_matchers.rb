RSpec::Matchers.define :include_header do |k, v|
  def matching_key(k, actual)
    actual.keys.find { |k2| k2.to_s.downcase == k.to_s.downcase }
  end

  match do |actual|
    matching_key = matching_key(k, actual)
    return false unless matching_key

    actual_value = actual[matching_key]
    if v.respond_to?(:match)
      v.match(actual_value)
    else
      v == actual_value
    end
  end

  failure_message do |actual|
    matching_key = matching_key(k, actual)
    return "expected #{k}: #{v} but no #{k} header was found" unless matching_key
    "expected #{k}: #{v} but found #{matching_key}: #{actual[matching_key]}"
  end
end
