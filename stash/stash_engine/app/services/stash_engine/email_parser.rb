module StashEngine

  class EmailParser

    def initialize(content:)
      @content = content
      parse
    end      

    def journal
      #TODO
      nil
    end

    def identifier
      #TODO
      nil
    end

    def manuscript_number
      #TODO
      nil
    end

    def article_status
      #TODO
      nil
    end

    def metadata_hash
      @hash
    end

    private
    
    def parse
      @lines = content_to_lines
      
      # convert the lines to a hash
      @hash = lines_to_hash
      puts "HASH #{hash}"
      
      # clean authors (and any other parts of the hash that need cleaning)
      # TODO clean_authors(hash)      
      
      j = find_journal
      puts "JOURNAL #{j}"
      
      # TODO ident = find_associated_identifier(hash)
    end

    # Breaks a large string of content into an array of lines,
    # stripping any material after the ending tag
    def content_to_lines
      lines = @content.split(%r{\n+|\r+|<br/>|<br />})
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
      @lines = lines
    end
    
    def lines_to_hash
      # Although journal emails may contain many fields, we only use the fields that are listed here
      allowed_tags = ["journal code", "journal name", "ms reference number", "ms title", "ms authors", "article status",
                      "publication doi", "keywords", "dryad data doi", "print issn", "online issn"]
      @hash = {}
      @lines.each_with_index do |line, index|
        puts "-- ln #{index} -- #{line}"
        next unless line.include?(':')
        colon_index = line.index(':')
        tag = line[0..colon_index-1].downcase
        # if the line starts with a valid tag, add it to the hash
        if allowed_tags.include?(tag)
          value = line[colon_index+1..].strip
          puts "  -- tag |#{tag}|#{value}|"
          @hash[tag] = value
        end
        # if the line starts the abstract, add all of the remaining lines, and break from the loop
        if tag == "abstract"
          value = line[colon_index+1..]
          remaining_lines = @lines[index+1..]
          value += ' ' + remaining_lines.join(' ') if remaining_lines.present?
          puts "  -- tag |#{tag}|#{value}|"
          @hash[tag] = value.strip
          break
        end
        
      end
      @hash
    end
    
    def find_journal
      puts "HASH #{@hash}"
      @journal = nil
      # prefer finding by journal code, fallback to ISSN or title
      @journal = StashEngine::Journal.where(journal_code: @hash['journal code'].downcase).first if @hash['journal code']
      puts "    -- j1 #{@journal}"
      return if @journal
            
      @journal = StashEngine::Journal.where(issn: @hash['print issn']).first if @hash['print issn']
      puts "    -- j2 #{@journal}"
      return if @journal
      
      @journal = StashEngine::Journal.where(issn: @hash['online issn']).first if @hash['online issn']
      puts "    -- j3 #{@journal}"
      return if @journal

      @journal = StashEngine::Journal.where(title: @hash['journal name']).first if @hash['journal name']

      puts "    -- j4 #{@journal}"
      @journal
    end

  end
end
