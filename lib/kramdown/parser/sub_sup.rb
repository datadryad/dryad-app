require 'kramdown'
require 'kramdown-parser-gfm'

module Kramdown
  module Parser
    class SubSup < Kramdown::Parser::GFM
      def initialize(source, options)
        super
        @span_parsers |= %i[superscript subscript]
      end

      SUPTAGSTART = /\^([^^]*)\^/
      SUBTAGSTART = /(?<!~)~(?!~)([^~]*)(?<!~)~(?!~)/

      def subsupparse(regex, tag)
        line = @src.current_line_number

        if @src[1].blank?
          add_text(@src.scan(regex))
        else
          @src.pos += 1
          el = Kramdown::Element.new(:html_element, tag, {}, category: :span, line: line)
          parse_spans(el, regex)
          @tree.children << el
          @src.pos += 1
        end
      end

      def parse_superscript
        subsupparse(/\^/, 'sup')
      end

      def parse_subscript
        subsupparse(/~/, 'sub')
      end

      define_parser(:superscript, SUPTAGSTART, '\^') unless has_parser?(:superscript)
      define_parser(:subscript, SUBTAGSTART, '(?<!~)~(?!~)') unless has_parser?(:subscript)
    end
  end
end
