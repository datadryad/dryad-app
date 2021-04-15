module StashEngine
  class Manuscript < ApplicationRecord
    belongs_to :journal
    belongs_to :identifier, optional: true

    # rubocop:disable Metrics/MethodLength
    def self.from_message_content(content:)
      puts("CON #{content}")
      result = OpenStruct.new(success?: false, error: 'No content')
      return result unless content

      lines = content_to_lines(content)

      # convert the lines to a hash
      hash = lines_to_hash(lines)
      puts "HASH #{hash}"
      
      # clean authors (and any other parts of the hash that need cleaning)
      # TODO clean_authors(hash)      

      # TODO j = find_journal(hash)

      # TODO ident = find_associated_identifier(hash)
      
#      mn = Manuscript.new(journal: j,
#                          identififier: ident,
#                          manuscript_number: hash['ms reference number'],
#                          status: hash['article status'],
#                          metadata: hash)

      if lines.present?
        result.delete_field('error')
        result[:success?] = true
#        result[:payload] = lines
      end

#      puts "RESULT #{result}"
      result
    end
    # rubocop:enable Metrics/MethodLength

    private

    # Breaks a large string of content into an array of lines,
    # stripping any material after the ending tag
    def self.content_to_lines(content)
      lines = content.split(%r{\n+|\r+|<br/>|<br />})
      puts "LIN #{lines}"
      # remove any lines after EndDryadContent
      last_dryad_line = 0
      lines.each_with_index do |val, index|
        puts "#{val} => #{index}"
        if val.include?('EndDryadContent')
          last_dryad_line = index
          break
        end
      end
      lines = lines[0..last_dryad_line - 1] if last_dryad_line > 0
      lines
    end

    def self.lines_to_hash(lines)
      # Although journal emails may contain many fields, we only use the fields that are listed here
      allowed_tags = ["journal code", "journal name", "ms reference number", "ms title", "ms authors", "article status",
                      "publication doi", "keywords", "dryad data doi"]
      hash = {}
      lines.each_with_index do |line, index|
        puts "-- ln #{index} -- #{line}"
        next unless line.include?(':')
        colon_index = line.index(':')
        tag = line[0..colon_index-1].downcase
        # if the line starts with a valid tag, add it to the hash
        if allowed_tags.include?(tag)
          value = line[colon_index+1..].strip
          puts "  -- tag |#{tag}|#{value}|"
          hash[tag] = value
        end
        # if the line starts the abstract, add all of the remaining lines, and break from the loop
        if tag == "abstract"
          value = line[colon_index+1..]
          remaining_lines = lines[index+1..]
          value += ' ' + remaining_lines.join(' ') if remaining_lines.present?
          puts "  -- tag |#{tag}|#{value}|"
          hash[tag] = value.strip
          break
        end
        
      end
      hash
    end
    
  end
end
