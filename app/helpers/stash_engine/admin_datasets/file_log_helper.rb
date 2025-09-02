# rubocop:disable Layout/LineLength, Metrics/AbcSize, Metrics/PerceivedComplexity

module StashEngine
  module AdminDatasets
    module FileLogHelper

      def pick_file_changes(changes)
        changes.reject do |change|
          # rubocop:disable Lint/DuplicateBranch
          # don't show copies or destroy events
          if change.object_changes['file_state']&.dig(1) == 'copied' || change.event == 'destroy'
            true
          # don't show the creation of files that are deleted in the same version
          elsif change.object_changes['file_state']&.dig(1) == 'created' &&
            @changes.any? { |v| v.event == 'destroy' && v.item_id == change.item_id }
            true
          # don't show system storage and validation
          elsif (change.object_changes.keys - %w[storage_version_id digest digest_type validated_at]).empty?
            true
          else
            false
          end
          # rubocop:enable Lint/DuplicateBranch
        end
      end

      def display_change(c)
        if c.event == 'update'
          if c.object_changes.keys == ['download_filename']
            "Renamed <del>#{c.object_changes['download_filename'][0]}</del> &rarr; <ins>#{c.object_changes['download_filename'][1]}</ins>".html_safe
          else
            file = @resource.generic_files.where(id: c.object['id']).first
            str = "#{c.object_changes['file_state']&.dig(1)&.capitalize}: "
            if file&.original_deposit_file
              str += "<a href=\"#{file.original_deposit_file.uploaded_success_url}\">#{c.object['download_filename'].presence || c.object['upload_file_name']}</a>"
              str += " (#{filesize(c.object['upload_file_size'])})"
            else
              str += "<em>#{c.object['download_filename']}</em>"
            end
            str.html_safe
          end
        else
          file = @resource.generic_files.where(id: c.object_changes['id']&.dig(1)).first
          str = "#{c.object_changes['file_state']&.dig(1)&.capitalize}: "
          if file&.original_deposit_file
            str += "<a href=\"#{file.original_deposit_file.uploaded_success_url}\">#{c.object_changes['download_filename']&.dig(1)&.presence || c.object_changes['upload_file_name']&.dig(1)}</a>"
            str += " (#{filesize(c.object_changes['upload_file_size']&.dig(1))})"
          else
            str += "<em>#{c.object_changes['download_filename']&.dig(1)}</em>"
          end
          str.html_safe
        end
      end

    end
  end
end
# rubocop:enable Layout/LineLength, Metrics/AbcSize, Metrics/PerceivedComplexity
