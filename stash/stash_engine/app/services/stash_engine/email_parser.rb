module StashEngine

  # rubocop:disable Metrics/ClassLength, Metrics/MethodLength
  class EmailParser
    attr_reader :journal, :identifier

    def initialize(content:)
      @content = content
      parse
    end

    def manuscript_number
      @hash['ms reference number']
    end

    def article_status
      @hash['article status']
    end

    def metadata_hash
      @hash
    end

    private

    def parse
      parse_content_to_lines
      lines_to_hash
      puts "HASH #{@hash}"

      find_journal
      puts "JOURNAL #{@journal}"

      parse_author_list
      puts "AUTH #{@hash['ms authors']}"

      find_associated_identifier
      puts "IDENT #{@identifier}"
    end

    # Breaks a large string of content into an array of lines,
    # stripping any material after the ending tag
    def parse_content_to_lines
      @lines = @content.split(%r{\n+|\r+|<br/>|<br />|<BR/>|<BR />})
      puts "LIN #{@lines}"
      # remove any lines after EndDryadContent
      last_dryad_line = 0
      @lines.each_with_index do |val, index|
        puts "#{val} => #{index}"
        if val.include?('EndDryadContent')
          last_dryad_line = index
          break
        end
      end
      @lines = @lines[0..last_dryad_line - 1] if last_dryad_line > 0
      @lines
    end

    def lines_to_hash
      # Although journal emails may contain many fields, we only use the fields that are listed here
      allowed_tags = ['journal code', 'journal name', 'ms reference number', 'ms title', 'ms authors', 'article status',
                      'publication doi', 'keywords', 'dryad data doi', 'print issn', 'online issn']
      downcase_tags = ['journal code', 'article status', 'publication doi', 'dryad data doi']
      @hash = {}.with_indifferent_access
      @lines.each_with_index do |line, index|
        puts "-- ln #{index} -- #{line}"
        next unless line.include?(':')

        colon_index = line.index(':')
        tag = line[0..colon_index - 1].downcase
        # if the line starts with a valid tag, add it to the hash
        if allowed_tags.include?(tag)
          value = line[colon_index + 1..].strip
          value.downcase! if downcase_tags.include?(tag)
          puts "  -- tag |#{tag}|#{value}|"
          @hash[tag] = value
        end
        # if the line starts the abstract, add all of the remaining lines, and break from the loop
        next unless tag == 'abstract'

        value = line[colon_index + 1..]
        remaining_lines = @lines[index + 1..]
        value += " #{remaining_lines.join(' ')}" if remaining_lines.present?
        puts "  -- tag |#{tag}|#{value}|"
        @hash[tag] = value.strip
        break

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

    def find_associated_identifier
      @identifier = nil
      # prefer finding by data doi
      data_doi = @hash['dryad data doi']
      puts "DATA DOI #{data_doi}"
      if data_doi
        data_doi.downcase!
        data_doi.sub!(/^doi:/, '')
        @identifier = StashEngine::Identifier.where(identifier: data_doi).first
      end

      # find by manuscript number
      ms_number = @hash['ms reference number']
      if ms_number && !@identifier
        int_data = StashEngine::InternalDatum.where(value: ms_number, data_type: 'manuscriptNumber')
        int_data.each do |datum|
          ident = datum.stash_identifier
          @identifier = ident if ident.journal == @journal
        end
      end

      @identifier
    end

    # Convert the author string into an array of names
    # Author lists generally come as either "last, first; last, first"
    # or as "first last, first last and first last" (sometimes with the Oxford comma before the 'and' token)
    def parse_author_list
      author_string = @hash['ms authors']
      return unless author_string

      authors = []

      # first check to see if the authors are semicolon-separated
      split_string = author_string.split(';')
      puts "SPLIT #{split_string}"

      # if it didn't have semicolons, it must have commas
      if split_string.size == 1
        split_string = author_string.split(',')

        # although, if there was only one author and it was listed as lastname, firstname, it would have a comma too...
        if split_string.length == 2 && !split_string[1].include?(' and ')
          authors << [split_string[0].strip, split_string[1].strip]
          split_string = []
        end
      end

      split_string.each do |auth|
        if auth.include?(' and ')
          # It's the end of the list, so we parse both names
          two_auths = auth.split(' and ')
          authors << parse_author_name(two_auths[0])
          authors << parse_author_name(two_auths[1])
        else
          authors << parse_author_name(auth)
        end
      end

      @hash['ms authors'] = authors
    end

    # Parse the name of a single author
    # @return {family_name:, given_name:}]
    def parse_author_name(auth)
      # Remove any leading title, like Dr., Mrs.
      auth.strip!
      auth.gsub!(/^[DM]+r*s*\.*\s+/, '')
      suffix = ''

      # is there a comma in the name?
      # it could either be lastname, firstname, or firstname lastname, title
      # rubocop:disable Style/CaseLikeIf
      comma_match = auth.match(/^(.+),\s*(.+)$/)
      if comma_match
        if comma_match[2].match(/(Jr\.*|Sr\.*|III)/)
          # if it's a suffix situation, then part 1 is "firstname lastname"
          # the last name will be the last word in group 1 + ", " + suffix
          suffix = ", #{comma_match[2].strip}"
          auth = comma_match[1]
        elsif comma_match[2].match(/(Ph|J)\.*D\.*|M\.*[DAS]c*\.*/)
          # if it's a title situation, throw the title away and assume the part before is "firstname lastname"
          auth = comma_match[1]
        else
          # it's simply "lastname, firstname", so return it in that order
          return { family_name: comma_match[1].strip, given_name: comma_match[2].strip }.with_indifferent_access
        end
      end
      # rubocop:enable Style/CaseLikeIf

      space_match = auth.match(/^(.+) +(.*)$/)
      if space_match
        { family_name: "#{space_match[2].strip}#{suffix}", given_name: space_match[1].strip }.with_indifferent_access
      else
        # there is only one word in the name: assign it to the familyName
        { family_name: auth, given_name: '' }.with_indifferent_access
      end
    end

  end
end
# rubocop:enable Metrics/ClassLength, Metrics/MethodLength
