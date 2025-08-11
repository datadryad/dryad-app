# rubocop:disable Metrics/ModuleLength, Layout/LineLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

module StashEngine
  module AdminDatasets
    module ChangeLogHelper

      def pick_changes(changes)
        sub_list = changes.find { |c| c.object_changes.empty? }&.additional_info&.dig('subjects_list') || []
        # rubocop:disable Lint/DuplicateBranch
        changes.reject do |change|
          case change.item_type
          when 'StashEngine::Resource'
            if change.object_changes.present? && (change.object_changes.keys & %w[title hold_for_peer_review accepted_agreement publication_date tenant_id display_readme]).empty?
              true
            elsif change.object_changes.empty? && change.additional_info&.dig('subjects_list') == sub_list
              true
            elsif change.object_changes.empty? && @changes.any? { |v| v.id > change.id && v.values_at(:whodunnit, :item_id, :item_type) == change.values_at(:whodunnit, :item_id, :item_type) && v.object_changes.empty? }
              true
            elsif @changes.any? { |v| v.id > change.id && v.values_at(:whodunnit, :item_id, :item_type) == change.values_at(:whodunnit, :item_id, :item_type) && v.object_changes.keys == change.object_changes.keys }
              true
            else
              false
            end
          else
            if @changes.any? { |v| v.id > change.id && v.values_at(:whodunnit, :item_id, :item_type) == change.values_at(:whodunnit, :item_id, :item_type) }
              true
            else
              false
            end
          end
          # rubocop:enable Lint/DuplicateBranch
        end
      end

      def resource_changes(c, _first)
        if c.object_changes.empty?
          "<dl><div>
            <dt>Subject list:</dt>
            <dd>#{c.additional_info&.dig('subjects_list')&.map { |s| s['subject'] }&.join(', ')}</dd>
          </div></dl>".html_safe
        else
          c.object_changes.map do |k, v|
            case k
            when 'title'
              "<dl><div><dt>Submission title:</dt><dd>#{v[1]}</dd></div></dl>"
            when 'hold_for_peer_review'
              "<div>#{v[1] ? 'Set' : 'Removed'} peer review hold</div>"
            when 'accepted_agreement'
              "<div>#{v[1] ? 'Accepted' : 'Removed acceptance of'} Dryad terms and conditions</div>"
            when 'publication_date'
              "<div>Set publication date to #{formatted_date(v[1])}</div>"
            when 'tenant_id'
              "<div>Submission institution ID is now #{v[1]}</div>"
            when 'display_readme'
              "<div>README #{v[1] ? 'will' : 'will not'} be displayed</div>"
            end
          end.join.html_safe
        end
      end

      def description_changes(c, first)
        desc_types = {
          abstract: 'abstract',
          methods: 'methods',
          other: 'usage notes',
          technicalinfo: 'README',
          hsi_statement: 'HSI statement',
          usage_notes: 'HSI statement',
          changelog: 'file change log'
        }
        original = first.object['description'] || ''
        latest = c.object['description'] || ''

        if %w[technicalinfo changelog hsi_statement usage_notes].include?(c.object['description_type'])
          original = markdown_render(original).to_s
          latest = markdown_render(latest).to_s
        end

        if c.event == 'update'
          str = "<div class=\"changes-header\">
            Updated #{desc_types[c.object['description_type'].to_sym]}"
          if original.present? || latest.present?
            str += "<button class=\"o-button__plain-text7 desc-changes-button\" aria-controls=\"desc_changes#{c.id}\" aria-expanded=\"false\">
              <i class=\"fas fa-eye\" aria-hidden=\"true\" style=\"margin-right: .35ch\"></i>View changes
            </button>"
          end
          str += "</div><div class=\"desc-changes\" id=\"desc_changes#{c.id}\" data-id=\"#{c.id}\" hidden></div>
            <div id=\"desc_original#{c.id}\" hidden>#{original}</div>
            <div id=\"desc_latest#{c.id}\" hidden>#{latest}</div>"

          str.html_safe
        else
          "Deleted #{desc_types[c.object_changes['description_type'][0]&.to_sym]}".html_safe
        end
      end

      def orcid_link(orcid)
        return "https://sandbox.orcid.org/#{orcid}" if APP_CONFIG.orcid.site == 'https://sandbox.orcid.org/'

        "https://orcid.org/#{orcid}"
      end

      def author_changes(c, _first)
        p c.additional_info
        if c.event == 'update'
          str = "<span>Set author information:</span><dl><div><dt>Name:</dt><dd>#{c.object['author_first_name']} #{c.object['author_last_name']}</dd></div>"
          if c.object['author_orcid'].present?
            str += "<div><dt>ORCID:</dt><dd><a href=\"#{orcid_link(c.object['author_orcid'])}\" target=\"_blank\" rel=\"noreferrer\">#{c.object['author_orcid']}</a></dd></div>"
          end
          if c.object['author_email'].present?
            str += "<div><dt>Email:</dt><dd>#{c.object['author_email']}</dd></div><div><dt>Publish email:</dt><dd>#{c.object['corresp']}</dd></div>"
          end
          if c.additional_info&.dig('affiliations_list')&.present?
            str += '<div><dt>Affiliations:</dt><dd>'
            str += c.additional_info['affiliations_list'].map do |aff|
              if aff['ror_id'].present?
                "<a href=\"#{aff['ror_id']}\" target=\"_blank\" rel=\"noreferrer\">#{aff['long_name']}</a>"
              else
                aff['long_name']
              end
            end.join(', ')
            str += '</dd></div>'
          end
          str += '</dl>'
          str.html_safe
        else
          "Deleted author (#{"#{c.object_changes['author_first_name'][0]} #{c.object_changes['author_last_name'][0]}".presence || '<em>empty</em>'})".html_safe
        end
      end

      def publication_changes(c, _first)
        str = '<span>Set associated publication:</span><dl>'
        if c.object['pub_type'] == 'primary_article'
          str += "<div><dt>Publication name:</dt><dd>#{c.object['publication_name']}</dd></div><div><dt>Publication ISSN:</dt><dd>#{c.object['publication_issn']}</dd></div><div><dt>Manuscript number:</dt><dd>#{c.object['manuscript_number']}</dd></div>"
        end
        if c.object['pub_type'] == 'preprint'
          str += "<div><dt>Preprint server:</dt><dd>#{c.object['publication_name']}</dd></div><div><dt>Server ISSN:</dt><dd>#{c.object['publication_issn']}</dd></div>"
        end
        str += '</dl>'
        str.html_safe
      end

      def work_changes(c, _first)
        if c.event == 'update'
          str = "<span>Set related work:</span><dl><div><dt>Work type:</dt><dd>#{c.object['work_type']}</dd></div>"
          if c.object['related_identifier'].present?
            str += "<div><dt>DOI/URL:</dt><dd><a href=\"#{c.object['related_identifier']}\" target=\"_blank\" rel=\"noreferrer\">#{c.object['related_identifier']}</a></dd></div>"
          end
          str += '</dl>'
          str.html_safe
        else
          "Deleted related work (#{c.object_changes['related_identifier'][0].presence || '<em>empty</em>'})".html_safe
        end
      end

      def contributor_changes(c, _first)
        if c.event == 'update'
          str = "<span>Set #{c.object['contributor_type']}:</span><dl><div><dt>Name:</dt><dd>#{c.object['contributor_name']}</dd></div>"
          if c.object['name_identifier_id'].present?
            str += "<div><dt>ROR ID:</dt><dd><a href=\"#{c.object['name_identifier_id']}\" target=\"_blank\" rel=\"noreferrer\">#{c.object['name_identifier_id']}</a></dd></div>"
          end
          if c.object['contributor_type'] == 'funder'
            str += "<div><dt>Award ID:</dt><dd>#{c.object['award_number']}</dd></div><div><dt>Award title:</dt><dd>#{c.object['award_title']}</dd></div><div><dt>Award description:</dt><dd>#{c.object['award_description']}</dd></div>"
          end
          str += '</dl>'
          str.html_safe
        else
          "Deleted #{c.object_changes['contributor_type'][0]} (#{c.object_changes['contributor_name'][0].presence || '<em>empty</em>'})".html_safe
        end
      end

      def change_logs
        {
          'StashEngine::Resource': :resource_changes,
          'StashDatacite::Description': :description_changes,
          'StashEngine::Author': :author_changes,
          'StashEngine::ResourcePublication': :publication_changes,
          'StashDatacite::RelatedIdentifier': :work_changes,
          'StashDatacite::Contributor': :contributor_changes
        }
      end

    end
  end
end

# rubocop:enable Metrics/ModuleLength, Layout/LineLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
