module StashEngine
  class Manuscript < ApplicationRecord
    belongs_to :journal
    belongs_to :identifier, optional: true

    # rubocop:disable Metrics/MethodLength
    def self.from_message_content(content:)
      puts("CON #{content}")
      result = OpenStruct.new(success?: false, error: 'No content')
      return result unless content

      # convert into lines
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
      lines = lines[0..last_dryad_line] if last_dryad_line > 0

      # determine the journal
      # make a manuscript object for that journal

      if lines.present?
        result.delete_field('error')
        result[:success?] = true
        result[:payload] = lines
      end

      puts "RESULT #{result}"
      result
    end
    # rubocop:enable Metrics/MethodLength
  end
end
