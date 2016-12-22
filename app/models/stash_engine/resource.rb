module StashEngine
  class Resource < ActiveRecord::Base
    # ------------------------------------------------------------
    # Relations

    has_many :file_uploads, class_name: 'StashEngine::FileUpload', dependent: :destroy
    has_one :stash_version, class_name: 'StashEngine::Version'
    belongs_to :identifier, class_name: 'StashEngine::Identifier', foreign_key: 'identifier_id'
    has_one :resource_usage, class_name: 'StashEngine::ResourceUsage'
    belongs_to :user, class_name: 'StashEngine::User'
    has_one :current_state,
            class_name: 'StashEngine::ResourceState',
            primary_key: 'current_resource_state_id',
            foreign_key: 'id'

    # ------------------------------------------------------------
    # Callbacks

    def init_state_and_version
      self.current_resource_state_id = ResourceState.create(resource_id: id, resource_state: 'in_progress', user_id: user_id).id
      self.stash_version = StashEngine::Version.create(resource_id: id, version: next_version_number, zip_filename: nil)
      save
    end
    after_create :init_state_and_version

    # ------------------------------------------------------------
    # Scopes

    scope :in_progress, (lambda do
      joins(:current_state).where(stash_engine_resource_states: { resource_state:  :in_progress })
    end)
    scope :submitted, (lambda do
      joins(:current_state).where(stash_engine_resource_states: { resource_state:  [:published, :processing, :error] })
    end)
    scope :by_version_desc, -> { joins(:stash_version).order('stash_engine_versions.version DESC') }
    scope :by_version, -> { joins(:stash_version).order('stash_engine_versions.version ASC') }

    # ------------------------------------------------------------
    # File upload utility methods

    def self.uploads_dir
      File.join(Rails.root, 'uploads')
    end

    def self.upload_dir_for(resource_id)
      File.join(uploads_dir, resource_id.to_s)
    end

    def upload_dir
      Resource.upload_dir_for(id)
    end

    # clean up the uploads with files that no longer exist for this resource
    def clean_uploads
      file_uploads.each do |fu|
        fu.destroy unless File.exist?(fu.temp_file_path)
      end
    end

    # gets the latest files that are not deleted in db, current files for this version
    def current_file_uploads
      subquery = FileUpload.where(resource_id: id).where("file_state <> 'deleted'")
                           .select('max(id) last_id, upload_file_name').group(:upload_file_name)
      FileUpload.joins("INNER JOIN (#{subquery.to_sql}) sub on id = sub.last_id").order(upload_file_name: :asc)
    end

    # the states of the latest files of the same name in the resource (version), included deleted
    def latest_file_states
      subquery = FileUpload.where(resource_id: id)
                           .select('max(id) last_id, upload_file_name').group(:upload_file_name)
      FileUpload.joins("INNER JOIN (#{subquery.to_sql}) sub on id = sub.last_id").order(upload_file_name: :asc)
    end

    # TODO: get amoeba to do this for us
    def copy_file_records_from(other_resource)
      file_uploads << other_resource.current_file_uploads.collect(&:dup)
      if file_uploads.any?
        file_uploads.each do |file|
          file.resource_id = id
          file.file_state = 'copied'
          file.save!
        end
      end
    end

    # ------------------------------------------------------------
    # Current resource state

    def published?
      current_resource_state.resource_state == 'published'
    end

    def processing?
      current_resource_state.resource_state == 'processing'
    end

    def current_resource_state_value
      current_resource_state.resource_state
    end

    def current_resource_state
      # You'd think we could use #current_state, but no, ActiveRecord gets confused in #current_state=
      ResourceState.find(current_resource_state_id)
    end

    def current_state=(state_string)
      return if state_string == current_resource_state_value
      my_state = current_resource_state
      my_state.resource_state = state_string
      my_state.save
    end

    # ------------------------------------------------------------
    # File submission

    def submit(sword_package)
      ensure_identifier(sword_package.doi)
      SwordJob.submit_async(sword_package)
    end

    # ------------------------------------------------------------
    # Identifiers

    def identifier_str
      ident = identifier
      return unless ident
      ident_type = ident.identifier_type
      ident && "#{ident_type && ident_type.downcase}:#{ident.identifier}"
    end

    def identifier_value
      ident = identifier
      ident && ident.identifier
    end

    def ensure_identifier(doi)
      doi_value = doi.start_with?('doi:') ? doi.split(':', 2)[1] : doi
      current_id_value = identifier_value
      return if current_id_value == doi_value
      if current_id_value
        raise ArgumentError, "Resource #{id} already has an identifier #{current_id_value}; can't set new value #{doi_value}"
      end

      existing_identifier = Identifier.find_by(identifier: doi_value, identifier_type: 'DOI')
      if existing_identifier
        self.identifier = existing_identifier
        version_record = stash_version
        version_record.version = next_version_number
        version_record.save!
      else
        self.identifier = Identifier.create(identifier: doi_value, identifier_type: 'DOI')
      end
      save!
    end

    # ------------------------------------------------------------
    # Versioning

    def version_number
      stash_version && stash_version.version
    end

    def next_version_number
      last_version = (identifier && identifier.last_submitted_version_number)
      last_version ? last_version + 1 : 1
    end

    def version_zipfile=(zipfile)
      version_record = stash_version
      version_record.zip_filename = File.basename(zipfile)
      version_record.save!
    end

    # ------------------------------------------------------------
    # Usage and statistics

    # total count of submitted datasets
    def self.submitted_dataset_count
      sql = %q(
        SELECT COUNT(DISTINCT r.identifier_id)
          FROM stash_engine_resources r
          JOIN stash_engine_resource_states rs
            ON r.current_resource_state_id = rs.id
         WHERE rs.resource_state = 'published'
      )
      connection.execute(sql).first[0]
    end

    def increment_downloads
      ensure_resource_usage
      resource_usage.increment(:downloads).save
    end

    def increment_views
      ensure_resource_usage
      resource_usage.increment(:views).save
    end

    private

    def ensure_resource_usage
      create_resource_usage(downloads: 0, views: 0) if resource_usage.nil?
    end
  end
end

