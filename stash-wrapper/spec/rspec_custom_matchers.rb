require 'rspec/expectations'
require 'equivalent-xml'

RSpec::Matchers.define :be_xml do |expected|

  def to_nokogiri(xml)
    return nil unless xml
    case xml
    when Nokogiri::XML::Element
      xml
    when Nokogiri::XML::Document
      xml.root
    when String
      to_nokogiri(Nokogiri::XML(xml))
    when REXML::Element
      to_nokogiri(xml.to_s)
    else
      fail "be_xml() expected XML, got #{xml.class}"
    end
  end

  def to_pretty(nokogiri)
    return nil unless nokogiri
    out = StringIO.new
    save_options = Nokogiri::XML::Node::SaveOptions::FORMAT | Nokogiri::XML::Node::SaveOptions::NO_DECLARATION
    nokogiri.write_xml_to(out, encoding: 'UTF-8', indent: 2, save_with: save_options)
    out.string
  end

  match do |actual|
    expected_xml = to_nokogiri(expected) || fail("expected value #{expected} does not appear to be XML")
    actual_xml = to_nokogiri(actual)

    EquivalentXml.equivalent?(expected_xml, actual_xml, element_order: false, normalize_whitespace: true)
  end

  failure_message do |actual|
    expected_string = to_pretty(to_nokogiri(expected))
    actual_string = to_pretty(to_nokogiri(actual)) || actual
    "expected XML:\n#{expected_string}\n\nbut was:\n#{actual_string}"
  end

  failure_message_when_negated do |actual|
    actual_xml = to_element(actual) || actual
    "expected not to get XML:\n\t#{actual_xml}"
  end
end

RSpec::Matchers.define :be_time do |expected|

  def to_string(time)
    time.is_a?(Time) ? time.utc.round(2).iso8601(2) : time.to_s
  end

  match do |actual|
    if expected
      fail "Expected value #{expected} is not a Time" unless expected.is_a?(Time)
      actual.is_a?(Time) && (to_string(expected) == to_string(actual))
    else
      return actual.nil?
    end
  end

  failure_message do |actual|
    expected_str = to_string(expected)
    actual_str = to_string(actual)
    "expected time:\n#{expected_str}\n\nbut was:\n#{actual_str}"
  end
end
