module Tasks
  module RelatedIdentifiers
    module Replacements

      def self.update_doi_prefix
        # update all starting with DOI and correct format into fixed_id: temp string.
        sql_update(
          sql_regex: '^doi:10\.[[:digit:]]{4,9}/[-._;()/:a-zA-Z0-9]+$',
          doi_starting_char: 5
        )
      end

      def self.update_bare_doi
        sql_update(
          sql_regex: '^10\.[[:digit:]]{4,9}/[-._;()/:a-zA-Z0-9]+$',
          doi_starting_char: 1
        )
      end

      def self.move_good_format
        sql_update(
          sql_regex: '^https://doi.org/10\.[[:digit:]]{4,9}/[-._;()/:a-zA-Z0-9]+$',
          doi_starting_char: 17
        )
      end

      def self.update_http_good
        sql_update(
          sql_regex: '^http://doi.org/10\.[[:digit:]]{4,9}/[-._;()/:a-zA-Z0-9]+$',
          doi_starting_char: 16
        )
      end

      def self.update_http_dx_doi
        sql_update(
          sql_regex: '^http://dx.doi.org/10\.[[:digit:]]{4,9}/[-._;()/:a-zA-Z0-9]+$',
          doi_starting_char: 19
        )
        sql_update(
          sql_regex: '^https://dx.doi.org/10\.[[:digit:]]{4,9}/[-._;()/:a-zA-Z0-9]+$',
          doi_starting_char: 20
        )
      end

      def self.update_protocol_free
        sql_update(
          sql_regex: '^dx.doi.org/10\.[[:digit:]]{4,9}/[-._;()/:a-zA-Z0-9]+$',
          doi_starting_char: 12
        )
        sql_update(
          sql_regex: '^doi.org/10\.[[:digit:]]{4,9}/[-._;()/:a-zA-Z0-9]+$',
          doi_starting_char: 9
        )
      end

      def self.update_non_ascii
        results = StashDatacite::RelatedIdentifier.where(
          "related_identifier_type = 'doi' AND related_identifier <> CONVERT(related_identifier USING ASCII)"
        )

        results.each do |result|
          ascii_string = ''
          result.related_identifier.chars.each do |char|
            ascii_string << char unless char.ord > 127
          end

          m = ascii_string.match(%r{10\.\d{4,9}/[-._;()/:a-zA-Z0-9]+})
          result.update(fixed_id: "https://doi.org/#{m}") if m
        end
      end

      def self.remaining_strings_containing_dois
        results = StashDatacite::RelatedIdentifier.where("related_identifier_type = 'doi' AND fixed_id IS NULL")

        results.each do |result|
          m = result.related_identifier.match(%r{10\.\d{4,9}/[-._;()/:a-zA-Z0-9]+})
          result.update(fixed_id: "https://doi.org/#{m}") if m
        end
      end

      def self.sql_update(sql_regex:, doi_starting_char:)
        related_ids = StashDatacite::RelatedIdentifier
          .where("related_identifier_type = 'doi' AND related_identifier REGEXP '#{sql_regex}'")
        related_ids.update_all("fixed_id = CONCAT('https://doi.org/', MID(related_identifier, #{doi_starting_char}))")
      end
    end
  end
end
