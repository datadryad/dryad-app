module StashEngine
  module PublicationUpdaterHelper

    def mergeable?(val1, val2)
      return formatted_date(val1) != formatted_date(val2) if val1.is_a?(Date) || val2.is_a?(Date)

      val1&.strip&.downcase != val2&.strip&.downcase
    end

    def render_column(old_val:, new_val:)
      return '<td></td>' unless old_val.present? || new_val.present?
      return "<td>#{new_val.present? ? new_val : 'Not available'}</td>" unless mergeable?(old_val, new_val)

      <<~HTML
        <td class="c-proposed-change-table__column-mergeable">
          #{new_val.present? ? new_val : 'Not available'}
          <div class="c-proposed-change-table__column-mergeable-icon">
            <em class="fa fa-arrow-down"></em>
          </div>
        </td>
      HTML
    end

    def fetch_identifier_metadata(resource:, data_type:)
      return nil unless resource.present? && data_type.present?
      resource.identifier.internal_data.where(data_type: data_type).first&.value || 'Not available'
    end

    def fetch_related_identifier_metadata(resource:, related_identifier_type:, relation_type:)
      return nil unless resource.present? && related_identifier_type.present? && relation_type.present?
      resource.related_identifiers.where(related_identifier_type: related_identifier_type,
                                         relation_type: relation_type).first&.value || 'Not available'
    end

    def existing_authors(resource:)
      return nil unless resource.present?
      resource.authors.map(&:author_full_name).uniq.sort { |a, b| a <=> b }.join('<br>')
    end

    def proposed_authors(json:)
      return nil unless json.present?
      JSON.parse(json).map { |a| "#{a['family']}, #{a['given']}" }.uniq.sort { |a, b| a <=> b }.join('<br>')
    rescue JSON::ParserError
      nil
    end

  end
end
