require 'stash/doi/datacite_gen'

# rubocop:disable Metrics/ClassLength
module Tasks
  module MigrationImport
    class Resource

      # ar means ActiveRecord object
      attr_reader :hash, :ar_identifier, :ar_resource, :ar_user_id

      def initialize(hash:, ar_identifier:)
        @hash = hash.with_indifferent_access

        disable_callback_methods
        create_base_resource

        if ar_identifier.nil?
          my_id = Stash::Doi::DataciteGen.mint_id(resource: @ar_resource)
          id_type, id_text = my_id.split(':', 2)
          ar_identifier = StashEngine::Identifier.create(identifier: id_text, identifier_type: id_type.upcase)
          @ar_resource.update(identifier_id: ar_identifier.id)
        end
        @ar_identifier = ar_identifier
        @ar_resource.update(identifier_id: @ar_identifier.id)
      end

      def import
        disable_callback_methods

        # a bunch of stash_engine things attached to the resource
        add_authors
        add_curation_activities
        add_edit_histories
        add_file_uploads
        add_queue_states
        # add_shares
        # This code will likely never be used again, for importing old dash datasets into the new database for Dryad
        add_submission_logs
        add_version

        # adding DataCite metadata
        add_contributors
        add_dcs_dates
        add_descriptions
        # formats, languages and name identifiers (for contributors) not used in Dash, though ORCIDs for authors are in author table instead
        add_geolocations
        add_publication_years
        add_publisher
        add_related_identifiers
        add_resource_type
        add_rights
        add_sizes
        add_subjects

        enable_callback_methods
      end

      def create_base_resource
        @ar_user_id = User.new(hash: hash[:user]).user_id
        save_hash = @hash.slice('created_at', 'updated_at', 'has_geolocation', 'download_uri', 'update_uri', 'title',
                                'publication_date', 'accepted_agreement', 'tenant_id', 'old_resource_id')
        save_hash.merge!(identifier_id: @ar_identifier&.id, skip_datacite_update: true, skip_emails: true, user_id: @ar_user_id,
                         current_editor_id: @ar_user_id)
        save_hash.merge!(embargo_fields)
        @ar_resource = StashEngine::Resource.create(save_hash)
        update_merritt_state
      end

      # disable the callback methods for this instance of the resource_object
      def disable_callback_methods
        StashEngine::Resource.skip_callback(:create, :after, :init_state_and_version)
        # StashEngine::Resource.skip_callback(:create, :after, :create_share)
      end

      def enable_callback_methods
        StashEngine::Resource.set_callback(:create, :after, :init_state_and_version)
        # StashEngine::Resource.set_callback(:create, :after, :create_share)
      end

      def embargo_fields
        return {} if @hash[:embargo].blank? || @hash[:embargo][:end_date].blank?

        my_time = Time.iso8601(@hash[:embargo][:end_date])
        return {} if my_time < Time.new

        { hold_for_peer_review: true, peer_review_end_date: my_time }
      end

      # this one is a bit weird because it need to both be written to another table and updated back in the resource for the latest state
      # and there is only really one state
      def update_merritt_state
        my_hash = @hash[:current_resource_state].slice('resource_state', 'created_at', 'updated_at').merge(user_id: @ar_user_id)
        @ar_resource.resource_states << StashEngine::ResourceState.create(my_hash)
        @ar_resource.update_column(:current_resource_state_id, @ar_resource.resource_states.first)
      end

      # --- stash tables ---

      def add_authors
        @hash[:authors].each do |json_author|
          my_hash = json_author.slice('author_first_name', 'author_last_name', 'author_email', 'author_orcid', 'created_at', 'updated_at')
            .merge(resource_id: @ar_resource.id)
          this_author = StashEngine::Author.create(my_hash)
          json_author[:affiliations].each do |json_affiliation|
            add_affiliation(ar_author: this_author, json_affiliation: json_affiliation)
          end
        end
      end

      def add_curation_activities
        my_state = @hash[:current_resource_state][:resource_state]
        out_state = if my_state == 'submitted'
                      if @hash[:embargo].blank? || @hash[:embargo][:end_date].blank? || Time.iso8601(@hash[:embargo][:end_date]) < Time.new
                        'published'
                      else
                        'embargoed'
                      end
                    else
                      'in_progress'
                    end
        @ar_resource.curation_activities << StashEngine::CurationActivity.create(status: out_state, user_id: ar_user_id)
      end

      def add_edit_histories
        @hash[:edit_histories].each do |json_eh|
          my_hash = json_eh.slice('user_comment', 'created_at', 'updated_at')
          @ar_resource.edit_histories << StashEngine::EditHistory.create(my_hash)
        end
      end

      def add_file_uploads
        @hash['file_uploads'].each do |json_file|
          my_hash = json_file.slice('upload_file_name', 'upload_content_type', 'upload_file_size', 'upload_updated_at',
                                    'created_at', 'updated_at', 'file_state', 'url', 'status_code',
                                    'timed_out', 'original_url', 'cloud_service')
          @ar_resource.data_files << StashEngine::DataFile.create(my_hash)
        end
      end

      def add_queue_states
        return unless @hash[:current_resource_state][:resource_state] == 'submitted'

        @ar_resource.repo_queue_states << StashEngine::RepoQueueState.create(state: 'completed', hostname: 'migrated-from-dash')
      end

      def add_shares
        return unless @hash[:share].present? && @hash[:share][:secret_id].present?

        my_hash = @hash[:share].slice('secret_id', 'created_at', 'updated_at').merge(resource_id: @ar_resource.id)
        StashEngine::Share.create(my_hash)
        # else
        # @ar_resource.create_share # in the new system, there is always a share
      end

      def add_submission_logs
        @hash[:submission_logs].each do |json_log|
          my_hash = json_log.slice('archive_response', 'created_at', 'updated_at', 'archive_submission_request')
          @ar_resource.submission_logs << StashEngine::SubmissionLog.create(my_hash)
        end
      end

      def add_version
        my_hash = @hash[:version].slice('version', 'zip_filename', 'created_at', 'updated_at', 'merritt_version').merge(resource_id: @ar_resource.id)
        StashEngine::Version.create(my_hash)
      end

      # --- these are methods to add DataCite metadata

      def add_contributors
        @hash[:contributors].each do |json_contrib|
          my_hash = json_contrib.slice('contributor_name', 'contributor_type', 'created_at', 'updated_at', 'award_number')
          @ar_resource.contributors << StashDatacite::Contributor.create(my_hash)
          # btw affiliations for contributors are not really used in Dash data, so skipping that headache, though we have some test data for it
        end
      end

      def add_dcs_dates
        @hash[:datacite_dates].each do |json_date|
          my_hash = json_date.slice('date', 'date_type', 'created_at', 'updated_at')
          @ar_resource.datacite_dates << StashDatacite::DataciteDate.create(my_hash)
        end
      end

      def add_descriptions
        @hash[:descriptions].each do |json_desc|
          my_hash = json_desc.slice('description', 'description_type', 'created_at', 'updated_at')
          @ar_resource.descriptions << StashDatacite::Description.create(my_hash)
        end
      end

      def add_publication_years
        @hash[:publication_years].each do |json_pub_year|
          my_hash = json_pub_year.slice('publication_year', 'created_at', 'updated_at')
          @ar_resource.publication_years << StashDatacite::PublicationYear.create(my_hash)
        end
      end

      def add_publisher
        return if @hash[:publisher].nil?

        my_hash = @hash[:publisher].slice('publisher', 'created_at', 'updated_at').merge(resource_id: @ar_resource.id)
        StashDatacite::Publisher.create(my_hash)
      end

      def add_related_identifiers
        @hash[:related_identifiers].each do |json_rel_id|
          my_hash = json_rel_id.slice('related_identifier', 'related_identifier_type', 'relation_type', 'related_metadata_scheme',
                                      'scheme_URI', 'scheme_type', 'created_at', 'updated_at')
          @ar_resource.related_identifiers << StashDatacite::RelatedIdentifier.create(my_hash)
        end
      end

      def add_resource_type
        return if @hash[:resource_type].nil?

        my_hash = @hash[:resource_type].slice('resource_type_general', 'resource_type', 'created_at',
                                              'updated_at').merge(resource_id: @ar_resource.id)
        StashDatacite::ResourceType.create(my_hash)
      end

      def add_rights
        @hash[:rights].each do |json_right|
          my_hash = json_right.slice('rights', 'rights_uri', 'created_at', 'updated_at')
          @ar_resource.rights << StashDatacite::Right.create(my_hash)
        end
      end

      def add_sizes
        @hash[:sizes].each do |json_size|
          my_hash = json_size.slice('size', 'created_at', 'updated_at')
          @ar_resource.sizes << StashDatacite::Size.create(my_hash)
        end
      end

      def add_subjects
        @hash[:subjects].each do |json_subject|
          existing_subjects = StashDatacite::Subject.where(subject: json_subject[:subject],
                                                           subject_scheme: json_subject[:subject_scheme],
                                                           scheme_URI: json_subject['scheme_URI'])
          if existing_subjects.empty?
            # Create & link subject
            my_hash = json_subject.slice('subject', 'subject_scheme', 'scheme_URI', 'created_at', 'updated_at')
            @ar_resource.subjects << StashDatacite::Subject.create(my_hash)
          else
            # link subject
            @ar_resource.subjects << existing_subjects.first
          end
        end
      end

      def add_geolocations
        @hash[:geolocations].each do |json_geo|
          geo_place = make_place(json_geo[:geolocation_place])
          geo_point = make_point(json_geo[:geolocation_point])
          geo_box = make_box(json_geo[:geolocaton_box])
          next if geo_place.nil? && geo_point.nil? && geo_box.nil?

          StashDatacite::Geolocation.create(resource_id: @ar_resource.id,
                                            place_id: geo_place&.id,
                                            point_id: geo_point&.id,
                                            box_id: geo_box&.id)
        end
      end

      def make_place(json_place)
        return nil if json_place.nil?

        my_hash = json_place.slice('geo_location_place', 'created_at', 'updated_at')
        StashDatacite::GeolocationPlace.create(my_hash)
      end

      def make_point(json_point)
        return nil if json_point.nil?

        my_hash = json_point.slice('latitude', 'longitude', 'created_at', 'updated_at')
        StashDatacite::GeolocationPoint.create(my_hash)
      end

      def make_box(json_box)
        return nil if json_box.nil?

        my_hash = json_box.slice('sw_latitude', 'ne_latitude', 'sw_longitude', 'ne_longitude', 'created_at', 'updated_at')
        StashDatacite::GeolocationBox.create(my_hash)
      end

      def add_affiliation(ar_author:, json_affiliation:)
        name = json_affiliation[:long_name] || json_affiliation[:short_name] || json_affiliation[:abbreviation]
        return if name.blank?

        name.strip!
        ar_existing_affil = StashDatacite::Affiliation.find_by(long_name: name)
        ar_existing_affil = make_affil_with_ror(name: name) if ar_existing_affil.blank?
        ar_existing_affil = make_rorless_affil(name: name) if ar_existing_affil.blank?
        ar_author.affiliations << ar_existing_affil
      end

      def make_affil_with_ror(name:)
        ror_affil = StashEngine::RorOrg.find_first_by_ror_name(name)
        return nil if ror_affil.nil?

        if name.downcase == ror_affil.name.downcase.strip
          # just write the ror name as the name in long name
          StashDatacite::Affiliation.create(long_name: ror_affil.name.strip, ror_id: ror_affil.id)
        else
          # write ror name into the short name so we can compare and fix since short name isn't normally used
          StashDatacite::Affiliation.create(short_name: ror_affil.name.strip, long_name: name, ror_id: ror_affil.id)
        end
      rescue StandardError
        # Ror pooped, ignore and the ROR module doesn't give a specific class of error so catching exception
        nil
      end

      def make_rorless_affil(name:)
        StashDatacite::Affiliation.create(long_name: name)
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
# :nocov:
