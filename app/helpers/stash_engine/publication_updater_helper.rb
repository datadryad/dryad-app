module StashEngine
  module PublicationUpdaterHelper

    def mergeable?(val1, val2)
      return !val1.include?(val2) if val1.is_a?(Array)

      val1&.to_s&.strip&.downcase != val2&.to_s&.strip&.downcase
    end

    def render_column(old_val:, new_val:)
      return '<td></td>' unless old_val.present? || new_val.present?
      return "<td>#{new_val.presence || 'Not available'}</td>" unless mergeable?(old_val, new_val)

      <<~HTML
        <td class="c-proposed-change-table__column-mergeable" aria-label="Merge into the above">
          #{new_val.presence || 'Not available'}
          <i class="fa fa-arrow-up c-proposed-change-table__column-mergeable-icon" role="img" aria-label="Replace above content with below"></i>
        </td>
      HTML
    end

    def render_row(old_val:, new_val:)
      return '<td></td>' unless old_val.present? || new_val.present?
      return "<td>#{new_val.presence || 'Not available'}</td>" unless mergeable?(old_val, new_val)

      <<~HTML
        <td class="record-updater-mergeable" aria-label="Merge into existing">
          <i class="fa fa-arrow-left" role="img" aria-label="Replace existing content with proposed"></i>
          #{new_val.presence || 'Not available'}
        </td>
      HTML
    end

    def fetch_related_primary_article(resource:)
      prim_art = resource.related_identifiers.primary_article.first
      return 'Not available' unless prim_art.present?

      id_str = prim_art&.related_identifier

      my_match = id_str.match(%r{/(10\..+)})
      # extract the doi in a bare format to match the json for the other
      if my_match.present?
        my_match[1]
      else
        id_str
      end
    end

    def fetch_related_identifier_metadata(resource:, related_identifier_type:, relation_type:)
      return nil unless resource.present? && related_identifier_type.present? && relation_type.present?

      resource.related_identifiers.where(related_identifier_type: related_identifier_type,
                                         relation_type: relation_type).first&.related_identifier || 'Not available'
    end

    def existing_authors(resource:)
      return nil unless resource.present?

      temp_authors = resource.authors&.map(&:author_full_name)&.uniq
      output_authors(authors: temp_authors)
    end

    def proposed_authors(json:)
      return nil unless json.present?

      temp_authors = JSON.parse(json)&.map { |a| "#{a['family']}, #{a['given']}" }&.uniq
      output_authors(authors: temp_authors)
    rescue JSON::ParserError
      nil
    end

    def output_authors(authors:)
      return authors[0..2]&.sort { |a, b| a <=> b }&. + ['et al.'] if authors.length > 3

      authors&.sort { |a, b| a <=> b }
    end

  end
end
