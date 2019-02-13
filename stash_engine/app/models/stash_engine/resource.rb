# require 'stash/indexer/indexing_resource'
require 'stash/indexer/solr_indexer'
# the following is required to make our wonky tests work and may break if we move stuff around
require_relative '../../../../stash_datacite/lib/stash/indexer/indexing_resource'

module StashEngine
  class Resource < ActiveRecord::Base # rubocop:disable Metrics/ClassLength
    # ------------------------------------------------------------
    # Relations

    has_many :authors, class_name: 'StashEngine::Author', dependent: :destroy
    has_many :file_uploads, class_name: 'StashEngine::FileUpload', dependent: :destroy
    has_many :edit_histories, class_name: 'StashEngine::EditHistory'
    has_one :stash_version, class_name: 'StashEngine::Version', dependent: :destroy
    belongs_to :identifier, class_name: 'StashEngine::Identifier', foreign_key: 'identifier_id'
    has_one :embargo, class_name: 'StashEngine::Embargo', dependent: :destroy
    has_one :share, class_name: 'StashEngine::Share', dependent: :destroy
    belongs_to :user, class_name: 'StashEngine::User'
    has_one :current_resource_state,
            class_name: 'StashEngine::ResourceState',
            primary_key: 'current_resource_state_id',
            foreign_key: 'id'
    has_one :editor, class_name: 'StashEngine::User', primary_key: 'current_editor_id', foreign_key: 'id'
    has_many :submission_logs, class_name: 'StashEngine::SubmissionLog', dependent: :destroy
    has_many :resource_states, class_name: 'StashEngine::ResourceState', dependent: :destroy
    has_many :edit_histories, class_name: 'StashEngine::EditHistory', dependent: :destroy
    has_many :curation_activities, class_name: 'StashEngine::CurationActivity', dependent: :destroy
    has_one :current_curation_activity,
            class_name: 'StashEngine::CurationActivity',
            primary_key: 'current_curation_activity_id',
            foreign_key: 'id'

    amoeba do
      include_association :authors
      include_association :embargo
      include_association :file_uploads
      customize(->(_, new_resource) do
        # you'd think 'include_association :current_resource_state' would do the right thing and deep-copy
        # the resource state, but instead it keeps the reference to the old one, so we need to clear it and
        # let init_version do its job
        new_resource.current_resource_state_id = nil
        new_resource.current_curation_activity_id = nil

        new_resource.file_uploads.each do |file|
          raise "Expected #{new_resource.id}, was #{file.resource_id}" unless file.resource_id == new_resource.id
          if file.file_state == 'created'
            file.file_state = 'copied'
            file.save
          end
        end

        # for some reason a where clause will not work with AR in this instance
        # new_resource.file_uploads.where(file_state: 'deleted').delete_all
        resources = new_resource.file_uploads.select { |ar_record| ar_record.file_state == 'deleted' }
        resources.each(&:delete)
      end)
    end

    # ------------------------------------------------------------
    # Callbacks

    def init_state_and_version
      init_state
      init_version
      save
    end

    def update_stash_identifier_last_resource
      return if identifier.nil?
      # identifier.update(latest_resource_id: id) # set to my resource_id
      res = Resource.where(identifier_id: identifier_id).order(id: :desc).first
      identifier.update_column(:latest_resource_id, res&.id) # no callbacks, does bad stuff when duplicating with amoeba dup
    end

    def remove_identifier_with_no_resources
      # if no more resources after a removal for a StashEngine::Identifier then there is no remaining content for that Identifier
      # only in-progress resources are destroyed, but there may be earlier submitted ones
      return if identifier_id.nil?
      res_count = Resource.where(identifier_id: identifier_id).count
      return if res_count.positive?
      Identifier.destroy(identifier_id)
    end

    before_create :init_curation_status
    after_create :init_state_and_version, :update_stash_identifier_last_resource
    # for some reason, after_create not working, so had to add after_update
    after_update :update_stash_identifier_last_resource
    after_destroy :remove_identifier_with_no_resources, :update_stash_identifier_last_resource

    # shouldn't be necessary but we have some stale data floating around
    def ensure_state_and_version
      return if stash_version && current_resource_state_id
      init_version unless stash_version
      init_state unless current_resource_state_id
      init_curation_status if curation_activities.empty?
      save
    end
    # We want to disable this when we don't need it since it really kills performance for finding a long
    # list of resources.  For example in the rails console, resource.all does another query for each item in the list
    # after_find :ensure_state_and_version

    # ------------------------------------------------------------
    # Scopes

    scope :in_progress, (-> do
      joins(:current_resource_state).where(stash_engine_resource_states: { resource_state:  %i[in_progress error] })
    end)
    scope :in_progress_only, (-> do
      joins(:current_resource_state).where(stash_engine_resource_states: { resource_state:  %i[in_progress] })
    end)
    scope :submitted, (-> do
      joins(:current_resource_state).where(stash_engine_resource_states: { resource_state:  %i[submitted processing] })
    end)
    scope :processing, (-> do
      joins(:current_resource_state).where(stash_engine_resource_states: { resource_state:  [:processing] })
    end)
    scope :error, (-> do
      joins(:current_resource_state).where(stash_engine_resource_states: { resource_state:  [:error] })
    end)
    scope :by_version_desc, -> { joins(:stash_version).order('stash_engine_versions.version DESC') }
    scope :by_version, -> { joins(:stash_version).order('stash_engine_versions.version ASC') }

    # gets the latest version per dataset and includes items that haven't been assigned an identifer yet but are initially in progress
    scope :latest_per_dataset, (-> do
      subquery = <<-SQL
        SELECT max(id) AS id FROM stash_engine_resources WHERE identifier_id IS NOT NULL GROUP BY identifier_id
        UNION
        SELECT id FROM stash_engine_resources WHERE identifier_id IS NULL
      SQL
      joins("INNER JOIN (#{subquery}) sub ON stash_engine_resources.id = sub.id ")
    end)

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
      subquery = FileUpload.where(resource_id: id).where("file_state <> 'deleted' AND " \
                                         '(url IS NULL OR (url IS NOT NULL AND status_code = 200))')
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

    # the size of this resource (created + copied files)
    def size
      file_uploads.where(file_state: %w[copied created]).sum(:upload_file_size)
    end

    # just the size of the new files
    def new_size
      file_uploads.where(file_state: %w[created]).sum(:upload_file_size)
    end

    # returns the upload type either :files, :manifest, :unknown (unknown if no files are started for this version yet)
    def upload_type
      return :manifest if file_uploads.newly_created.url_submission.count > 0
      return :files if file_uploads.newly_created.file_submission.count > 0
      :unknown
    end

    # returns the list of fileuploads with duplicate names in created state where we shouldn't have any
    # rubocop:disable Metrics/MethodLength
    def duplicate_filenames
      sql = <<-SQL
        SELECT *
        FROM stash_engine_file_uploads AS a
        JOIN (SELECT upload_file_name
          FROM stash_engine_file_uploads
          WHERE resource_id = ? AND (file_state IS NULL OR file_state = 'created')
          GROUP BY upload_file_name HAVING count(*) >= 2) AS b
        ON a.upload_file_name = b.upload_file_name
        WHERE a.resource_id = ?
      SQL
      FileUpload.find_by_sql([sql, id, id])
    end
    # rubocop:enable Metrics/MethodLength

    def url_in_version?(url)
      file_uploads.where(url: url).where(file_state: 'created').where(status_code: 200).count > 0
    end

    # ------------------------------------------------------------
    # Special merritt download URLs

    # this takes the download URI we get from merritt for the whole object and manipulates it into a producer download
    # the version number is the merritt version number, or nil for latest version
    # TODO: this knows about merritt specifics transforming the sword url into a merritt url, needs to be elsewhere
    def merritt_producer_download_uri
      return nil if download_uri.nil?
      return nil unless download_uri =~ %r{^https*://[^/]+/d/\S+$}
      version_number = stash_version.merritt_version
      "#{download_uri.sub('/d/', '/u/')}/#{version_number}"
    end

    # TODO: we need a better way to get a Merritt local_id and domain than ripping it from the headlines
    # (ie the Sword download URI)

    # returns two parts the protocol_and_domain part of the URL (with no trailing slash) and the local_id
    def merritt_protodomain_and_local_id
      return nil if download_uri.nil?
      return nil unless download_uri =~ %r{^https*://[^/]+/d/\S+$}
      matches = download_uri.match(%r{^(https*://[^/]+)/d/(\S+)$})
      [matches[1], matches[2]]
    end

    # ------------------------------------------------------------
    # Current resource state

    def submitted?
      current_state == 'submitted'
    end

    def processing?
      current_state == 'processing'
    end

    def embargoed?
      return false if current_state != 'submitted'
      private?
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
    # Curation helpers
    def curatable?
      submitted?
    end

    # Shortcut to the current curation activity's status
    def current_curation_status
      current_curation_activity.status
    end

    # Create the initial CurationActivity
    def init_curation_status
      curation_activities << StashEngine::CurationActivity.new
    end
    private :init_curation_status

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
      raise TypeError, "Unsupported identifier type #{ident_type}" unless ident_type == 'DOI'
      "https://doi.org/#{ident.identifier}"
    end

    def identifier_value
      ident = identifier
      ident && ident.identifier
    end

    def ensure_identifier(doi)
      current_id_value = identifier_value
      doi_value = doi.start_with?('doi:') ? doi.split(':', 2)[1] : doi
      return if current_id_value == doi_value
      raise ArgumentError, "Resource #{id} already has an identifier #{current_id_value}; can't set new value #{doi_value}" if current_id_value
      ensure_identifier_and_version(doi_value)
    end

    def ensure_identifier_and_version(doi_value)
      existing_identifier = Identifier.find_by(identifier: doi_value, identifier_type: 'DOI')
      if existing_identifier
        self.identifier = existing_identifier
        increment_version!
      else
        self.identifier = Identifier.create(identifier: doi_value, identifier_type: 'DOI')
      end
      save!
    end
    private :ensure_identifier_and_version

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
      self.stash_version = StashEngine::Version.create(
        resource_id: id,
        version: next_version_number,
        merritt_version: next_merritt_version,
        zip_filename: nil
      )
    end
    private :init_version

    def increment_version!
      version_record = stash_version
      version_record.version = next_version_number
      version_record.merritt_version = next_merritt_version
      version_record.save!
    end
    private :increment_version!

    # ------------------------------------------------------------
    # Ownership

    def tenant
      return nil unless tenant_id
      Tenant.find(tenant_id)
    end

    # -----------------------------------------------------------
    # Permissions

    # can edit means they are not locked out because edits in progress and have permission
    def can_edit?(user:)
      permission_to_edit?(user: user) && (dataset_in_progress_editor.id == user.id || user.superuser?)
    end

    # have the permission to edit
    def permission_to_edit?(user:)
      return false unless user
      # superuser, dataset owner or admin for the same tenant
      user.superuser? || user_id == user.id || (user.tenant_id == tenant_id && user.role == 'admin')
    end

    # ------------------------------------------------------------
    # Usage and statistics

    # TODO: EMBARGO: do we care about published vs. embargoed in this count?
    # total count of submitted datasets
    def self.submitted_dataset_count
      sql = "
        SELECT COUNT(DISTINCT r.identifier_id)
          FROM stash_engine_resources r
          JOIN stash_engine_resource_states rs
            ON r.current_resource_state_id = rs.id
         WHERE rs.resource_state = 'submitted'
      "
      connection.execute(sql).first[0]
    end

    # -----------------------------------------------------------
    # Authors

    def fill_blank_author!
      return if authors.count > 0 || user.blank? # already has some authors filled in or no user to know about
      fill_author_from_user!
    end

    def fill_author_from_user!
      f_name = user.first_name
      l_name = user.last_name
      orcid = (user.orcid.blank? ? nil : user.orcid)
      email = user.email
      StashEngine::Author.create(resource_id: id, author_orcid: orcid,
                                 author_first_name: f_name, author_last_name: l_name, author_email: email)
      # disabling because we no longer wnat this with UC Press
      # author.affiliation_by_name(user.tenant.short_name) if user.try(:tenant)
    end

    # -----------------------------------------------------------
    # Embargoes

    def private?
      !public?
    end

    def public?
      end_date = embargo && embargo.end_date
      return true unless end_date
      Time.now >= end_date
    end

    # -----------------------------------------------------------
    # editor

    # gets the in progress editor, if any, for the whole dataset
    # nil means no in progress dataset or the owner is the one in progress
    def dataset_in_progress_editor_id
      return current_editor_id if identifier.nil? # no identifier, has to be in progress
      return identifier.in_progress_resource.current_editor_id if identifier.in_progress?
      nil
    end

    # calculated current editor name, ignores nil current editor as current logged in user
    def dataset_in_progress_editor
      return user if dataset_in_progress_editor_id.nil?
      User.where(id: dataset_in_progress_editor_id).first
    end

    # -----------------------------------------------------------
    # SOLR actions for this resource

    def submit_to_solr
      solr_indexer = Stash::Indexer::SolrIndexer.new(solr_url: Blacklight.connection_config[:url])
      ir = Stash::Indexer::IndexingResource.new(resource: self)
      result = solr_indexer.index_document(solr_hash: ir.to_index_document) # returns true/false for success of operation
      update(solr_indexed: true) if result
    end

    def delete_from_solr
      solr_indexer = Stash::Indexer::SolrIndexer.new(solr_url: Blacklight.connection_config[:url])
      result = solr_indexer.delete_document(doi: identifier.to_s) # returns true/false for success of operation
      update(solr_indexed: false) if result
    end

    # -----------------------------------------------------------
    # Dates

    # What the publication date would be, if the resource was
    # submitted right now. Use this when you don't know/care
    # whether the resource has been submitted or not.
    def notional_publication_date
      embargo_end_date = embargo && embargo.end_date
      existing_pub_date = publication_date
      embargo_end_date || existing_pub_date || Time.now
    end

    # Called on submit
    def update_publication_date!
      self.publication_date = notional_publication_date
    end

    # notional_publication_year, as a string(!)
    def notional_publication_year
      return notional_publication_date.year.to_s if publication_years.blank?
      publication_years.first.publication_year
    end
  end
end
