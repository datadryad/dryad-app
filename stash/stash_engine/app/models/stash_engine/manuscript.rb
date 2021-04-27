module StashEngine
  class Manuscript < ApplicationRecord
    belongs_to :journal
    belongs_to :identifier, optional: true
    serialize :metadata

    # Create a new Manuscript from the content of an email message
    def self.from_message_content(content:)
      result = OpenStruct.new(success?: false, error: 'No content')
      return result unless content

      parser = EmailParser.new(content: content)
      parsing_error = check_parsing_errors(parser)

      if !parsing_error
        manu = Manuscript.create(journal: parser.journal,
                                 identifier: parser.identifier,
                                 manuscript_number: parser.manuscript_number,
                                 status: parser.article_status,
                                 metadata: parser.metadata_hash)

        if manu.present? && manu.id.present?
          result.delete_field('error')
          result[:success?] = true
          result[:payload] = manu
        end
      else
        result[:error] = parsing_error
      end

      result
    end

    def self.check_parsing_errors(parser)
      return 'Unable to locate Journal -- either through Journal Code or an ISSN' unless parser.journal
      return 'Article Status not found' unless parser.article_status
      unless parser.manuscript_number || parser.identifier
        return 'Unable to identify manuscript -- either through MS Reference Number or Dryad Data DOI'
      end

      hash = parser.metadata_hash
      return 'Unable to create metadata hash' unless hash.present?
      return 'Unable to parse MS Authors' unless hash['ms authors'].present?
      return 'Unable to locate MS Title' unless hash['ms title'].present?

      nil
    end
  end
end
