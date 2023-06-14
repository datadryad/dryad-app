module StashEngine
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
      find_journal
      parse_keywords
      parse_author_list
      parse_manuscript_number
      find_associated_identifier
    end

    # Breaks a large string of content into an array of lines,
    # stripping any material after the ending tag
    def parse_content_to_lines
      @lines = @content.split(%r{\n+|\r+|<br>|<br/>|<br />|<BR>|<BR/>|<BR />})
      # remove any lines after EndDryadContent
      last_dryad_line = 0
      @lines.each_with_index do |val, index|
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
      transformed_tags = { 'manuscript number' => 'ms reference number',
                           'article title' => 'ms title',
                           'all authors' => 'ms authors' }
      @hash = {}.with_indifferent_access
      @lines.each_with_index do |line, index|
        next unless line.include?(':')

        colon_index = line.index(':')
        tag = line[0..colon_index - 1].downcase
        # if the tag is a legacy tag used by journals with the old EditorialManager style, transform it into a normal tag
        tag = transformed_tags[tag] if transformed_tags.keys.include?(tag)
        # if the line starts with a valid tag, add it to the hash
        if allowed_tags.include?(tag)
          value = line[colon_index + 1..].strip
          value.downcase! if downcase_tags.include?(tag)
          @hash[tag] = value
        end
        # if the line starts the abstract, add all of the remaining lines, and break from the loop
        next unless tag == 'abstract'

        value = line[colon_index + 1..]
        remaining_lines = @lines[index + 1..]
        value += " #{remaining_lines.join(' ')}" if remaining_lines.present?
        @hash[tag] = value.strip
        break

      end
      @hash
    end

    def find_journal
      @journal = nil
      # prefer finding by journal code, fallback to ISSN or title
      @journal = StashEngine::Journal.where(journal_code: @hash['journal code'].downcase).first if @hash['journal code']
      return if @journal

      @journal = StashEngine::Journal.find_by_issn(@hash['print issn']) if @hash['print issn']
      return if @journal

      @journal = StashEngine::Journal.find_by_issn(@hash['online issn']) if @hash['online issn']
      return if @journal

      @journal = StashEngine::Journal.find_by_title(@hash['journal name']) if @hash['journal name']

      @journal
    end

    def find_associated_identifier
      @identifier = nil
      # prefer finding by data doi
      data_doi = @hash['dryad data doi']
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
          # It's the end of the list, so we parse both names,
          # but check to ensure they are both present
          two_auths = auth.split(' and ')
          auth1 = parse_author_name(two_auths[0])
          authors << auth1 if auth1['family_name'].present?
          auth2 = parse_author_name(two_auths[1])
          authors << auth2 if auth2['family_name'].present?
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
      comma_match = auth.match(/^(.+),\s*(.+)$/)
      if comma_match
        if comma_match[2].match(/(Jr\.*|Sr\.*|III)/)
          # if it's a suffix situation, then part 1 is "firstname lastname"
          # the last name will be the last word in group 1 + ", " + suffix
          suffix = ", #{comma_match[2].strip}"
          auth = comma_match[1]
        elsif comma_match[2].match(/(Ph|J)\.*\s*D\.*|M\.*\s*[DAS]c*\.*|B\.*\s*S\.*/)
          # if it's a trailing title (Ph.D, M.D.), throw the title away and assume the part before is "firstname lastname"
          auth = comma_match[1]
        else
          # it's simply "lastname, firstname", so return it in that order
          return { family_name: comma_match[1].strip, given_name: comma_match[2].strip }.with_indifferent_access
        end
      end
      space_match = auth.match(/^(.+) +(.*)$/)
      if space_match
        { family_name: "#{space_match[2].strip}#{suffix}", given_name: space_match[1].strip }.with_indifferent_access
      else
        # there is only one word in the name: assign it to the familyName
        { family_name: auth, given_name: '' }.with_indifferent_access
      end
    end

    def parse_keywords
      return [] if @hash['keywords'].blank?

      @hash['keywords'] = @hash['keywords'].split(/[,;]/).map(&:strip)
    end

    # Apply the journal's regex to the manuscript number, removing any irrelevant parts
    def parse_manuscript_number
      regex = @journal&.manuscript_number_regex
      return if regex.blank?

      msid = @hash['ms reference number']
      return if msid.blank? || msid.match(regex).blank?

      result = msid.match(regex)[1]
      @hash['ms reference number'] = result if result.present?
    end

  end
end
