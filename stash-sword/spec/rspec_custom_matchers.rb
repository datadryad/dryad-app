require 'rspec/expectations'

# Workaround for https://github.com/rspec/rspec-mocks/issues/1086
class RSpec::Mocks::ErrorGenerator # rubocop:disable Style/ClassAndModuleChildren
  unless respond_to?(:_default_error_message)
    alias _default_error_message default_error_message

    def default_error_message(expectation, expected_args, actual_args)
      failures = [_default_error_message(expectation, expected_args, actual_args)]
      expectation.expected_args.each do |expected|
        failures << expected.failure_message if expected.respond_to?(:failure_message)
      end
      failures.join("\n  ")
    end
  end
end

def value_for(key:, in_hash:)
  matching_key = in_hash.keys.find { |k| k.to_s.casecmp(key.to_s.downcase).zero? }
  in_hash[matching_key] if matching_key
end

def header?(key:, value:, in_hash:)
  actual_values = value_for(key: key, in_hash: in_hash)
  actual_values = [actual_values] unless actual_values.is_a?(Array)
  actual_values.find do |actual_value|
    if value.nil?
      actual_value.nil?
    elsif value.respond_to?(:match)
      actual_value && value.match(actual_value)
    else
      value == actual_value
    end
  end
end

def all?(headers:, in_hash:)
  headers.each do |k, v|
    return false unless header?(key: k, value: v, in_hash: in_hash)
  end
  true
end

def basic_auth(username, password)
  'Basic ' + ["#{username}:#{password}"].pack('m').delete("\r\n")
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
    @expected_auth = basic_auth(username, password)
    # value_for(key: 'Authorization', in_hash: actual.to_hash) == @expected_auth ? true : false
  end

  def failures_for(actual) # rubocop:disable Metrics/CyclomaticComplexity
    return ["Expected Net::HTTPRequest, got: #{actual.class}"] unless actual.is_a?(Net::HTTPRequest)
    failures = []
    failures << "Expected method #{@method}, got: #{actual.method}" if bad_method(actual)
    failures << "Expected uri #{@expected_uri}, got: #{actual.uri}" if bad_uri(actual)
    failures << "Expected headers #{expected_headers}, got: #{actual.to_hash}" if bad_headers(actual)
    auth_value = value_for(key: 'Authorization', in_hash: actual.to_hash)
    failures << "Expected Authorization header #{@expected_auth}, got: #{auth_value || 'nil'}" if bad_auth(actual)
    failures
  end

  def bad_method(actual)
    actual.method != @method.to_s.upcase if @method
  end

  def bad_uri(actual)
    actual.uri != @expected_uri if @expected_uri
  end

  def bad_headers(actual)
    !all?(headers: @expected_headers, in_hash: actual.to_hash) if @expected_headers
  end

  def bad_auth(actual)
    !header?(key: 'Authorization', value: @expected_auth, in_hash: actual.to_hash) if @expected_auth
  end

end

RSpec::Matchers.define :include_header do |k, v|
  def matching_key(k, actual)
    actual.keys.find { |k2| k2.to_s.casecmp(k.to_s.downcase).zero? }
  end

  match do |actual|
    all?(headers: { k => v }, in_hash: actual)
  end

  failure_message do |actual|
    "expected #{k} to be '#{v}' but found '#{value_for(key: k, in_hash: actual) || 'nil'}'"
  end
end
