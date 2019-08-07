module MigrationImport
  class Resource

    # ar means ActiveRecord object
    attr_reader :hash, :ar_identifier, :ar_resource, :ar_user_id

    def initialize(hash:, ar_identifier:)
      @hash = hash.with_indifferent_access
      @ar_identifier = ar_identifier
    end


    def import
      disable_callback_methods
      create_base_resource

      # a bunch of stash_engine things attached to the resource
      add_authors
      add_curation_activities
      add_edit_histories
      add_file_uploads
      add_queue_states
      add_shares
      add_submission_logs
      add_version

      # adding DataCite metadata
      # TODO: add affiliations for authors with ROR ids, not used for real data for contributors in Dash afaict
      add_contributors
      add_dcs_dates
      add_descriptions
      # formats, languages and name identifiers (for contributors) not used in Dash, though ORCIDs for authors in author table
      # TODO: adding locations later, complicated
      add_publication_years




      enable_callback_methods
    end

    def create_base_resource
      @ar_user_id = User.new(hash: hash[:user]).user_id
      save_hash = @hash.slice(*%w[created_at updated_at has_geolocation download_uri update_uri title publication_date
          accepted_agreement tenant_id])
      save_hash.merge!(identifier_id: @ar_identifier.id, skip_datacite_update: true, skip_emails: true, user_id: @ar_user_id,
                       current_editor_id: @ar_user_id)
      save_hash.merge!(embargo_fields)
      @ar_resource = StashEngine::Resource.create(save_hash)
      update_merritt_state
    end

    # disable the callback methods for this instance of the resource_object
    def disable_callback_methods
      StashEngine::Resource.skip_callback(:create, :after, :init_state_and_version)
      StashEngine::Resource.skip_callback(:create, :after, :update_stash_identifier_last_resource)
      StashEngine::Resource.skip_callback(:create, :after, :create_share)
      StashEngine::Resource.skip_callback(:update, :after, :update_stash_identifier_last_resource)
    end

    def enable_callback_methods
      StashEngine::Resource.set_callback(:create, :after, :init_state_and_version)
      StashEngine::Resource.set_callback(:create, :after, :update_stash_identifier_last_resource)
      StashEngine::Resource.set_callback(:create, :after, :create_share)
      StashEngine::Resource.set_callback(:update, :after, :update_stash_identifier_last_resource)
    end

    def embargo_fields
      return {} if @hash[:embargo].blank? || @hash[:embargo][:end_date].blank?
      my_time = Time.iso8601(@hash[:embargo][:end_date])
      return {} if my_time < Time.new
      {hold_for_peer_review: true, peer_review_end_date: my_time}
    end

    # this one is a bit weird because it need to both be written to another table and updated back in the resource for the latest state
    # and there is only really one state
    def update_merritt_state
      my_hash = @hash[:current_resource_state].slice(*%w[resource_state created_at updated_at]).merge(user_id: @ar_user_id)
      @ar_resource.resource_states << StashEngine::ResourceState.create(my_hash)
      @ar_resource.update_column(:current_resource_state_id, @ar_resource.resource_states.first)
    end


    # --- stash tables ---

    def add_authors
      @hash[:authors].each do |json_author|
        my_hash = json_author.slice(*%w[author_first_name author_last_name author_email author_orcid created_at updated_at])
        @ar_resource.authors << StashEngine::Author.create(my_hash)
        # TODO: Handle affilications which is a subhash
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
      @ar_resource.update_column(:current_curation_activity_id, @ar_resource.curation_activities.first)
    end

    def add_edit_histories
      @hash[:edit_histories].each do |json_eh|
        my_hash = json_eh.slice(*%w[user_comment created_at updated_at])
        @ar_resource.edit_histories << StashEngine::EditHistory.create(my_hash)
      end
    end

    def add_file_uploads
      @hash['file_uploads'].each do |json_file|
        my_hash = json_file.slice(*%w[upload_file_name upload_content_type upload_file_size upload_updated_at created_at
              updated_at temp_file_path file_state url status_code timed_out original_url cloud_service])
        @ar_resource.file_uploads << StashEngine::FileUpload.create(my_hash)
      end
    end

    def add_queue_states
      if @hash[:current_resource_state][:resource_state] == 'submitted'
        @ar_resource.repo_queue_states << StashEngine::RepoQueueState.create(state: 'completed', hostname: 'migrated-from-dash')
      end
    end

    def add_shares
      if @hash[:share].present? && @hash[:share][:secret_id].present?
        my_hash = @hash[:share].slice(*%w[secret_id created_at updated_at]).merge(resource_id: @ar_resource.id)
        StashEngine::Share.create(my_hash)
      else
        @ar_resource.create_share # in the new system, there is always a share
      end
    end

    def add_submission_logs
      @hash[:submission_logs].each do |json_log|
        my_hash = json_log.slice(*%w[archive_response created_at updated_at archive_submission_request])
        @ar_resource.submission_logs << StashEngine::SubmissionLog.create(my_hash)
      end
    end

    def add_version
      my_hash = @hash[:version].slice(*%w[version zip_filename created_at updated_at merritt_version]).merge(resource_id: @ar_resource.id)
      StashEngine::Version.create(my_hash)
    end

    # --- these are methods to add DataCite metadata

    # Affiliations are complicated and may require network lookups for ROR ids and may be really under authors
    # Contributors don't seem to actually be used in Dash for contributors
    def add_affiliation
      # TODO: make a complicated and annoying thing happen here
      nil
    end

    def add_contributors
      @hash[:contributors].each do |json_contrib|
        my_hash = json_contrib.slice(*%w[contributor_name contributor_type created_at updated_at award_number])
        @ar_resource.contributors << StashDatacite::Contributor.create(my_hash)
        # btw affiliations for contributors are not really used in Dash data, so skipping that headache, though we have some test data for it
      end
    end

    def add_dcs_dates
      @hash[:datacite_dates].each do |json_date|
        my_hash = json_date.slice(*%w[date date_type created_at updated_at])
        @ar_resource.datacite_dates << StashDatacite::DataciteDate.create(my_hash)
      end
    end

    def add_descriptions
      @hash[:descriptions].each do |json_desc|
        my_hash = json_desc.slice(*%w[description description_type created_at updated_at])
        @ar_resource.descriptions << StashDatacite::Description.create(my_hash)
      end
    end

    def add_publication_years
      @hash[:publication_years].each do |json_pub_year|
        my_hash = json_pub_year.slice(*%w[publication_year created_at updated_at])
        @ar_resource.publication_years << StashDatacite::PublicationYear.create(my_hash)
      end
    end

  end
end