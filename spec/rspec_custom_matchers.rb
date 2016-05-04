require 'rspec/expectations'

def basic_encode(username, password)
  result = 'Basic ' + ["#{username}:#{password}"].pack('m').delete("\r\n")
  puts "encoding #{username}:#{password} as #{result}"
  result
end

def header_value(k, headers)
  key = headers.keys.find { |k2| k2.to_s.downcase == k.to_s.downcase }
  puts "#{k}: #{key} => #{headers[key] if key}"
  headers[key] if key
end

RSpec::Matchers.define :request_for do |h|

  def failures_for(actual, h)

    failures = []

    uri = h[:uri]
    (failures << "Wrong URI: expected #{uri} but was #{actual.uri || 'nil'}") if uri unless actual.uri == uri

    method = h[:method]
    (failures << "Wrong method: expected #{method} but was #{actual.method || 'nil'}") if method unless actual.method == method

    headers = h[:headers]
    if headers
      headers.each do |k, v|
        actual_value = header_value(k, actual.to_hash)
        (failures << "Wrong value for header #{k}: expected #{v}, was #{actual_value || 'nil'}") unless actual_value == v
      end
    end

    username = h[:username]
    if username
      expected     = basic_encode(h[:username], h[:password])
      actual_value = header_value('Authorization', actual.to_hash)
      (failures << "Wrong value for Authorization header: expecrted #{expected}, was #{actual_value || 'nil'}") unless actual_value == expected
    end

    failures
  end

  match do |actual|
    failures_for(actual, h).empty?
  end

  failure_message do |actual|
    failures_for(actual, h).join('; ')
  end
end

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
