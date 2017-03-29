module StashEngine
  class Resource < ActiveRecord::Base
    # ------------------------------------------------------------
    # Relations

    has_many :file_uploads, class_name: 'StashEngine::FileUpload', dependent: :destroy
    has_one :stash_version, class_name: 'StashEngine::Version'
    belongs_to :identifier, class_name: 'StashEngine::Identifier', foreign_key: 'identifier_id'
    has_one :resource_usage, class_name: 'StashEngine::ResourceUsage'
    has_one :embargo, class_name: 'StashEngine::Embargo', dependent: :destroy
    has_one :share, class_name: 'StashEngine::Share', dependent: :destroy
    belongs_to :user, class_name: 'StashEngine::User'
    has_one :current_resource_state,
            class_name: 'StashEngine::ResourceState',
            primary_key: 'current_resource_state_id',
            foreign_key: 'id'

    amoeba do
      include_association :embargo
      include_association :file_uploads
      customize(lambda do |_, new_resource|
        # you'd think 'include_association :current_resource_state' would do the right thing and deep-copy
        # the resource state, but instead it keeps the reference to the old one, so we need to clear it and
        # let init_version do its job
        new_resource.current_resource_state_id = nil

        new_resource.file_uploads.each do |file|
          raise "Expected #{new_resource.id}, was #{file.resource_id}" unless file.resource_id == new_resource.id
          if file.file_state == 'created'
            file.file_state = 'copied'
            file.save
          end
        end
        new_resource.file_uploads.where(file_state: 'deleted').delete_all
      end)
    end

    # ------------------------------------------------------------
    # Patch points

    def primary_title
      raise NoMethodError, 'Metadata engine should patch Resource to implement :primary_title'
    end

    # ------------------------------------------------------------
    # Callbacks

    def init_state_and_version
      init_state
      init_version
      save
    end
    after_create :init_state_and_version

    # shouldn't be necessary but we have some stale data floating around
    def ensure_state_and_version
      return if stash_version && current_resource_state_id
      init_version unless stash_version
      init_state unless current_resource_state_id
      save
    end
    # TODO: we may want to disable this if/when we don't need it since it really kills performance for finding a long
    # list of resources.  For example in the rails console, resource.all does another query for each item in the list
    after_find :ensure_state_and_version

    # ------------------------------------------------------------
    # Scopes

    scope :in_progress, (lambda do
      joins(:current_resource_state).where(stash_engine_resource_states: { resource_state:  :in_progress })
    end)
    scope :submitted, (lambda do
      joins(:current_resource_state).where(stash_engine_resource_states: { resource_state:  [:submitted, :processing, :error] })
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

    # gets new files in this version
    def new_file_uploads
      subquery = FileUpload.where(resource_id: id).where("file_state = 'created'")
                     .select('max(id) last_id, upload_file_name').group(:upload_file_name)
      FileUpload.joins("INNER JOIN (#{subquery.to_sql}) sub on id = sub.last_id").order(upload_file_name: :asc)
    end

    # the states of the latest files of the same name in the resource (version), included deleted
    def latest_file_states
      subquery = FileUpload.where(resource_id: id)
                           .select('max(id) last_id, upload_file_name').group(:upload_file_name)
      FileUpload.joins("INNER JOIN (#{subquery.to_sql}) sub on id = sub.last_id").order(upload_file_name: :asc)
    end

    # ------------------------------------------------------------
    # Special merritt download URLs

    # this takes the download URI we get from merritt for the whole object and manipulates it into a producer download
    # the version number is the merritt version number, or nil for latest version
    # TODO: this knows about merritt specifics transforming the sword url into a merritt url, needs to be elsewhere
    def merritt_producer_download_uri
      return nil if download_uri.nil?
      return nil unless download_uri.match(/^https*:\/\/[^\/]+\/d\/\S+$/)
      version_number = stash_version.merritt_version
      "#{download_uri.sub('/d/', '/u/')}/#{version_number}"
    end

    # TODO: we need a better way to get a Merritt local_id and domain then ripping it from the headlines
    # (ie the Sword download URI)
    def merritt_domain_and_local_id
      return nil if download_uri.nil?
      return nil unless download_uri.match(/^https*:\/\/[^\/]+\/d\/\S+$/)
      matches = download_uri.match(/^https*:\/\/([^\/]+)\/d\/(\S+)$/)
      [matches[1], matches[2]]
    end

    # ------------------------------------------------------------
    # Current resource state

    # TODO: EMBARGO: change this to :submitted?, and/or check embargo dates/status and add :embargoed?
    def published?
      current_resource_state.resource_state == 'submitted'
    end

    def processing?
      current_resource_state.resource_state == 'processing'
    end

    def current_state
      current_resource_state && current_resource_state.resource_state
    end

    def current_state=(value)
      return if value == current_state
      my_state = current_resource_state
      raise "current_resource_state not initialized for resource #{id}" unless my_state
      my_state.resource_state = value
      my_state.save
    end

    def init_state
      self.current_resource_state_id = ResourceState.create(resource_id: id, resource_state: 'in_progress', user_id: user_id).id
    end
    private :init_state

    # ------------------------------------------------------------
    # Identifiers

    def identifier_str
      ident = identifier
      return unless ident
      ident_type = ident.identifier_type
      ident && "#{ident_type && ident_type.downcase}:#{ident.identifier}"
    end

    def identifier_uri
      ident = identifier
      return unless ident
      ident_type = ident.identifier_type
      raise TypeError, "Unsupported identifier type #{ident_type}" unless 'DOI' == ident_type
      "https://doi.org/#{ident.identifier}"
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
        version_record.merritt_version = next_merritt_version
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
      last_version_number = (identifier && identifier.last_submitted_version_number)
      last_version_number ? last_version_number + 1 : 1
    end

    # TODO: get this out of StashEngine into Stash::Merritt
    def merritt_version
      stash_version && stash_version.merritt_version
    end

    def next_merritt_version
      last_version = (identifier && identifier.last_submitted_resource)
      last_version ? last_version.merritt_version + 1 : 1
    end

    def version_zipfile=(zipfile)
      version_record = stash_version
      version_record.zip_filename = File.basename(zipfile)
      version_record.save!
    end

    def init_version
      # we probably don't have an identifier at this point so the version and merritt_version will probably always be 1, but you never know
      self.stash_version = StashEngine::Version.create(resource_id: id, version: next_version_number, merritt_version: next_merritt_version, zip_filename: nil)
    end
    private :init_version

    # ------------------------------------------------------------
    # Ownership

    def tenant
      Tenant.find(tenant_id)
    end

    def tenant_id
      user.tenant_id
    end

    # ------------------------------------------------------------
    # Usage and statistics

    # TODO: EMBARGO: do we care about published vs. embargoed in this count?
    # total count of submitted datasets
    def self.submitted_dataset_count
      sql = %q(
        SELECT COUNT(DISTINCT r.identifier_id)
          FROM stash_engine_resources r
          JOIN stash_engine_resource_states rs
            ON r.current_resource_state_id = rs.id
         WHERE rs.resource_state = 'submitted'
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

    # -----------------------------------------------------------
    # Embargoes
    def under_embargo?
      return false if embargo.nil? || embargo.end_date.nil?
      Time.new < embargo.end_date
    end

    private

    def ensure_resource_usage
      create_resource_usage(downloads: 0, views: 0) if resource_usage.nil?
    end
  end
end

