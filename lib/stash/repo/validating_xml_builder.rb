require 'mime-types'
# require 'file_builder'

module Stash
  module Repo
    class ValidatingXMLBuilder < FileBuilder

      def do_validate?
        (rails_env = ENV.fetch('RAILS_ENV', nil)) && %w[development test].include?(rails_env)
      end

      def mime_type
        MIME::Types['text/xml'].first
      end

      def contents
        @contents ||= begin
          xml = build_xml
          validate(xml) if do_validate?
          xml
        end
      end

      def validate(xml)
        doc = Nokogiri::XML(xml)
        errors = schema.validate(doc)
        return xml if errors.empty?

        logger.error(errors.join("\n"))
        raise errors[0]
      end

      def build_xml
        raise NoMethodError, "#{self.class} should override #build_xml to produce an XML string, but it doesn't"
      end

      # @return the Nokogiri::XML::Schema that should be used to validate the XML
      def schema
        raise NoMethodError, "#{self.class} should override #schema to provide an XML schema, but it doesn't"
      end
    end
  end
end
