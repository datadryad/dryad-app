require 'kramdown'
require 'kramdown-parser-gfm'

module Kramdown
  module Parser
    class SubSup < Kramdown::Parser::GFM
      def initialize(source, options)
        super
        @span_parsers -= [:escaped_chars]
        @span_parsers |= %i[superscript subscript escaped_characters]
      end

      SUPTAGSTART = /\^([^^]*)\^/
      SUBTAGSTART = /(?<!~)~(?!~)([^~]*)(?<!~)~(?!~)/
      ESCAPED_CHARS = /\\([\\.*_+`<>()\[\]{}#!:|"'$=-~^])/

      def subsupparse(regex, char, tag)
        line = @src.current_line_number
        saved_pos = @src.save_pos

        if @src[1].blank?
          add_text(@src.scan(regex))
        else
          @src.pos += 1
          el = Kramdown::Element.new(:html_element, tag, {}, category: :span, line: line)
          found = parse_spans(el, regex)
          if found
            @tree.children << el
          else
            @src.revert_pos(saved_pos)
            add_text(char)
          end
          @src.pos += 1
        end
      end

      def parse_superscript
        subsupparse(/\^/, '^', 'sup')
      end

      def parse_subscript
        subsupparse(/~/, '~', 'sub')
      end

      def parse_escaped_characters
        @src.pos += @src.matched_size
        add_text(@src[1])
      end

      define_parser(:superscript, SUPTAGSTART, '\^') unless has_parser?(:superscript)
      define_parser(:subscript, SUBTAGSTART, '(?<!~)~(?!~)') unless has_parser?(:subscript)
      define_parser(:escaped_characters, ESCAPED_CHARS, '\\\\') unless has_parser?(:escaped_characters)
    end
  end
end
