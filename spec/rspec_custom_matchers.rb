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
      File.open("tmp/#{now}-expected.xml", 'w') { |f| f.write(expected_string) }
      File.open("tmp/#{now}-actual.xml", 'w') { |f| f.write(actual_string) }

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
