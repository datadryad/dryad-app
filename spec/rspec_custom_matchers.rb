require 'rspec/expectations'

# Workaround for https://github.com/rspec/rspec-mocks/issues/1086
class RSpec::Mocks::ErrorGenerator
  unless respond_to?(:_default_error_message)
    alias_method :_default_error_message, :default_error_message

    def default_error_message(expectation, expected_args, actual_args)
      failures = [_default_error_message(expectation, expected_args, actual_args)]
      expectation.expected_args.each do |expected|
        if expected.respond_to?(:failure_message)
          failures << expected.failure_message
        end
      end
      failures.join("\n  ")
    end
  end
end

def value_for(key:, in_hash:)
  matching_key = in_hash.keys.find { |k| k.to_s.downcase == key.to_s.downcase }
  in_hash[matching_key] if matching_key
end

def has_header(key:, value:, in_hash:)
  actual_values = value_for(key: key, in_hash: in_hash)
  unless actual_values.respond_to?(:[])
    actual_values = [actual_values]
  end
  actual_values.find do |actual_value|
    value.respond_to?(:match) ? value.match(actual_value) : value == actual_value
  end
end

def has_all(headers:, in_hash:)
  headers.each do |k, v|
    return false unless has_header(key: k, value: v, in_hash: in_hash)
  end
  true
end

RSpec::Matchers.define :request do
  match do |actual|
    failures_for(actual).empty?
  end

  failure_message do |actual|
    failures_for(actual).join('; ')
  end

  chain :with_method do |method|
    @method = method
  end

  chain :with_uri do |expected_uri|
    @expected_uri = expected_uri
    # actual.uri == expected_uri
  end

  chain :with_headers do |expected_headers|
    @expected_headers = expected_headers
    # has_all(headers: expected_headers, in_hash: actual.to_hash).empty
  end

  chain :with_auth do |username, password|
    @expected_auth = 'Basic ' + ["#{username}:#{password}"].pack('m').delete("\r\n")
    # value_for(key: 'Authorization', in_hash: actual.to_hash) == @expected_auth ? true : false
  end

  def failures_for(actual)
    return ["Expected Net::HTTPRequest, got: #{actual.class}"] unless actual.is_a?(Net::HTTPRequest)

    failures = []
    if @method
      failures << "Expected method #{@method}, got: #{actual.method}" unless actual.method == @method.to_s.upcase
    end
    if @expected_uri
      failures << "Expected uri #{@expected_uri}, got: #{actual.uri}" unless actual.uri == @expected_uri
    end
    if @expected_headers
      failures << "Expected headers #{expected_headers}, got: #{actual.to_hash}" unless has_all(headers: @expected_headers, in_hash: actual.to_hash)
    end
    if @expected_auth
      unless has_header(key: 'Authorization', value: @expected_auth, in_hash: actual.to_hash)
        auth_value = value_for(key: 'Authorization', in_hash: actual.to_hash)
        failures << "Expected Authorization header #{@expected_auth}, got: #{auth_value || 'nil'}"
      end
    end
    failures
  end

end

RSpec::Matchers.define :include_header do |k, v|
  def matching_key(k, actual)
    actual.keys.find { |k2| k2.to_s.downcase == k.to_s.downcase }
  end

  match do |actual|
    has_all(headers: {k => v}, in_hash: actual)
  end

  failure_message do |actual|
    "expected #{k}: #{v} but found #{value_for(key: k, in_hash: actual)}"
  end
end
