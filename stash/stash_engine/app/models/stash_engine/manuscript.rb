module StashEngine
  class Manuscript < ApplicationRecord
    belongs_to :journal
    belongs_to :identifier, optional: true

    # Create a new Manuscript from the content of an email message
    def self.from_message_content(content:)
      puts("CON #{content}")
      result = OpenStruct.new(success?: false, error: 'No content')
      return result unless content
      
      parser = EmailParser.new(content: content)
      
      manu = Manuscript.create(journal: parser.journal,
                               identifier: parser.identifier,
                               manuscript_number: parser.manuscript_number,
                               status: parser.article_status,
                               metadata: parser.metadata_hash)
      
      if manu.present?
        result.delete_field('error')
        result[:success?] = true
        result[:payload] = manu
      end
      
      result
    end
    
  end
end
