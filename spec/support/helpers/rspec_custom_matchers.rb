require 'rspec/expectations'
require 'equivalent-xml'
require 'diffy'

module Stash
  module XMLMatchUtils
    def self.to_nokogiri(xml)
      return nil unless xml

      case xml
      when Nokogiri::XML::Element
        xml
      when Nokogiri::XML::Document
        xml.root
      when String
        to_nokogiri(Nokogiri::XML(xml, &:noblanks))
      when REXML::Element
        to_nokogiri(xml.to_s)
      else
        raise "be_xml() expected XML, got #{xml.class}"
      end
    end

    def self.to_pretty(nokogiri)
      return nil unless nokogiri

      out = StringIO.new
      save_options = Nokogiri::XML::Node::SaveOptions::FORMAT | Nokogiri::XML::Node::SaveOptions::NO_DECLARATION
      nokogiri.write_xml_to(out, encoding: 'UTF-8', indent: 2, save_with: save_options)
      out.string
    end

    def self.equivalent?(expected, actual, filename = nil)
      expected_xml = to_nokogiri(expected) || raise("expected value #{expected || 'nil'} does not appear to be XML#{" in #{filename}" if filename}")
      actual_xml = to_nokogiri(actual)

      EquivalentXml.equivalent?(expected_xml, actual_xml, element_order: false, normalize_whitespace: true)
    end

    def self.failure_message(expected, actual, filename = nil)
      expected_string = to_pretty(to_nokogiri(expected))
      actual_string = to_pretty(to_nokogiri(actual)) || actual

      now = Time.now.to_i
      File.write("/tmp/#{now}-expected.xml", expected_string)
      File.write("/tmp/#{now}-actual.xml", actual_string)

      diff = Diffy::Diff.new(expected_string, actual_string).to_s(:text)

      "expected XML differs from actual#{" in #{filename}" if filename}:\n#{diff}"
    end

    def self.to_xml_string(actual)
      to_pretty(to_nokogiri(actual))
    end

    def self.failure_message_when_negated(actual, filename = nil)
      "expected not to get XML#{" in #{filename}" if filename}:\n\t#{to_xml_string(actual) || 'nil'}"
    end
  end
end

RSpec::Matchers.define :be_xml do |expected, filename = nil|
  match do |actual|
    Stash::XMLMatchUtils.equivalent?(expected, actual, filename)
  end

  failure_message do |actual|
    Stash::XMLMatchUtils.failure_message(expected, actual, filename)
  end

  failure_message_when_negated do |actual|
    Stash::XMLMatchUtils.failure_message_when_negated(actual, filename)
  end
end

RSpec::Matchers.define :be_time do |expected|
  def to_string(time)
    time.is_a?(Time) ? time.utc.round(2).iso8601(2) : time.to_s
  end

  match do |actual|
    return actual.nil? unless expected
    raise "Expected value #{expected} is not a Time" unless expected.is_a?(Time)

    actual.is_a?(Time) && (to_string(expected) == to_string(actual))
  end

  failure_message do |actual|
    expected_str = to_string(expected)
    actual_str = to_string(actual)
    "expected time:\n#{expected_str}\n\nbut was:\n#{actual_str}"
  end
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

  def failures_for(actual)
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
  Array(actual_values).find do |actual_value|
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
  auth_string = ["#{username}:#{password}"].pack('m').delete("\r\n")
  "Basic #{auth_string}"
end
