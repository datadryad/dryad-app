# require 'stash/indexer/indexing_resource'
require 'stash/aws/s3'
require 'stash/indexer/solr_indexer'
# the following is required to make our wonky tests work and may break if we move stuff around
require_relative '../../../../stash_datacite/lib/stash/indexer/indexing_resource'

module StashEngine
  class Resource < ApplicationRecord # rubocop:disable Metrics/ClassLength
    # ------------------------------------------------------------
    # Relations

    has_many :authors, class_name: 'StashEngine::Author', dependent: :destroy
    has_many :file_uploads, class_name: 'StashEngine::FileUpload', dependent: :destroy
    has_many :software_uploads, class_name: 'StashEngine::SoftwareUpload', dependent: :destroy
    has_many :edit_histories, class_name: 'StashEngine::EditHistory'
    has_one :stash_version, class_name: 'StashEngine::Version', dependent: :destroy
    belongs_to :identifier, class_name: 'StashEngine::Identifier', foreign_key: 'identifier_id'
    belongs_to :user, class_name: 'StashEngine::User'
    has_one :current_resource_state,
            class_name: 'StashEngine::ResourceState',
            primary_key: 'current_resource_state_id',
            foreign_key: 'id'
    has_one :editor, class_name: 'StashEngine::User', primary_key: 'current_editor_id', foreign_key: 'id'
    has_many :submission_logs, class_name: 'StashEngine::SubmissionLog', dependent: :destroy
    has_many :resource_states, class_name: 'StashEngine::ResourceState', dependent: :destroy
    has_many :edit_histories, class_name: 'StashEngine::EditHistory', dependent: :destroy
    has_many :curation_activities, -> { order(id: :asc) }, class_name: 'StashEngine::CurationActivity', dependent: :destroy
    has_many :repo_queue_states, class_name: 'StashEngine::RepoQueueState', dependent: :destroy
    has_many :download_histories, class_name: 'StashEngine::DownloadHistory', dependent: :destroy
    has_many :zenodo_copies, class_name: 'StashEngine::ZenodoCopy', dependent: :destroy
    # download tokens are for Merritt version downloads with presigned URL caching
    has_one :download_token, class_name: 'StashEngine::DownloadToken', dependent: :destroy

    accepts_nested_attributes_for :curation_activities

    # ensures there is always an associated download_token record
    def download_token
      super || build_download_token(token: nil, available: nil)
    end

    amoeba do
      include_association :authors
      include_association :file_uploads
      include_association :software_uploads
      customize(->(_, new_resource) do
        # you'd think 'include_association :current_resource_state' would do the right thing and deep-copy
        # the resource state, but instead it keeps the reference to the old one, so we need to clear it and
        # let init_version do its job
        new_resource.current_resource_state_id = nil
        # do not mark these resources for public view until they've been re-curated and embargoed/published again
        new_resource.meta_view = false
        new_resource.file_view = false

        # this is a new rubocop cop complaint (must not be locked to a version of testing).
        # I think this may have been done for some reason (two separate loops) because of mutation or errors, IDK.
        # I'm not going to go back and revise right now.
        # rubocop:disable Style/CombinableLoops
        %i[file_uploads software_uploads].each do |meth|
          new_resource.public_send(meth).each do |file|
            raise "Expected #{new_resource.id}, was #{file.resource_id}" unless file.resource_id == new_resource.id

            if file.file_state == 'created'
              file.file_state = 'copied'
              file.save
            end
          end
        end

        # for some reason a where clause will not work with AR in this instance
        # new_resource.file_uploads.where(file_state: 'deleted').delete_all
        %i[file_uploads software_uploads].each do |meth|
          resources = new_resource.public_send(meth).select { |ar_record| ar_record.file_state == 'deleted' }
          resources.each(&:delete)
        end
        # rubocop:enable Style/CombinableLoops
      end)
    end

    # ------------------------------------------------------------
    # Callbacks

    def init_state_and_version
      init_state
      init_version
      init_curation_status
      save
      # Need to reload self here because some of the associated dependencies
      # update back on this object when they save (e.g. current_resource_state, etc.)
      reload
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

    def remove_s3_temp_files
      Stash::Aws::S3.delete_dir(s3_key: s3_dir_name(type: 'base'))
    end

    after_create :init_state_and_version, :update_stash_identifier_last_resource
    # for some reason, after_create not working, so had to add after_update
    after_update :update_stash_identifier_last_resource
    before_destroy :remove_s3_temp_files
    after_destroy :remove_identifier_with_no_resources, :update_stash_identifier_last_resource

    # shouldn't be necessary but we have some stale data floating around
    def ensure_state_and_version
      return if stash_version && current_resource_state_id

      init_version unless stash_version
      init_state unless current_resource_state_id
      init_curation_status if curation_activities.empty?
      save
    end

    # ------------------------------------------------------------
    # Scopes for Merritt status, which used to be the only status we had
    default_scope { includes(:curation_activities) }

    scope :in_progress, (-> do
      joins(:current_resource_state).where(stash_engine_resource_states: { resource_state:  %i[in_progress error] })
    end)
    scope :in_progress_only, (-> do
      joins(:current_resource_state).where(stash_engine_resource_states: { resource_state:  %i[in_progress] })
    end)
    scope :submitted, (-> do
      joins(:current_resource_state).where(stash_engine_resource_states: { resource_state:  %i[submitted processing] })
    end)
    scope :submitted_only, (-> do
      joins(:current_resource_state).where(stash_engine_resource_states: { resource_state:  %i[submitted] })
    end)
    scope :processing, (-> do
      joins(:current_resource_state).where(stash_engine_resource_states: { resource_state:  [:processing] })
    end)
    scope :error, (-> do
      joins(:current_resource_state).where(stash_engine_resource_states: { resource_state:  [:error] })
    end)
    scope :by_version_desc, -> { joins(:stash_version).order('stash_engine_versions.version DESC') }
    scope :by_version, -> { joins(:stash_version).order('stash_engine_versions.version ASC') }

    scope :latest_curation_activity_per_resource, -> do
      joins(:curation_activities).group('stash_engine_resources.id')
        .maximum('stash_engine_curation_activities.id')
        .collect { |k, v| { resource_id: k, curation_activity_id: v } }
    end

    # ------------------------------------------------------------
    # Scopes for curation status, which is now how we know about public display (and should imply successful Merritt submission status)
    scope :latest_curation_activity, ->(resource_id = nil) do
      rslts = joins(:curation_activities)
      rslts = rslts.where(stash_engine_resources: { id: resource_id }) if resource_id.present?
      rslts.group('stash_engine_resources.id').maximum('stash_engine_curation_activities.id')
    end

    scope :with_public_metadata, -> do
      where(meta_view: true)
    end

    scope :files_published, -> do
      # this also depends on the publication updater to update statuses to published daily
      where(file_view: true)
    end

    # this is METADATA published
    scope :published, -> do
      joins(:curation_activities).where('stash_engine_resources.publication_date < ?', Time.now.utc)
        .where(stash_engine_curation_activities: { id: latest_curation_activity.values,
                                                   status: %w[published embargoed] })
    end

    # complicated join & subquery that may be reused to get the last curation state for each resource
    SUBQUERY_FOR_LATEST_CURATION = <<~HEREDOC
      SELECT resource_id, max(id) as id
      FROM stash_engine_curation_activities
      GROUP BY resource_id
    HEREDOC
      .freeze

    JOIN_FOR_LATEST_CURATION = "INNER JOIN (#{SUBQUERY_FOR_LATEST_CURATION}) subq ON stash_engine_resources.id = subq.resource_id " \
                               'INNER JOIN stash_engine_curation_activities ON subq.id = stash_engine_curation_activities.id'.freeze

    JOIN_FOR_INTERNAL_DATA = 'INNER JOIN stash_engine_identifiers ON stash_engine_identifiers.id = stash_engine_resources.identifier_id ' \
                             'LEFT OUTER JOIN stash_engine_internal_data ' \
                             'ON stash_engine_internal_data.identifier_id = stash_engine_identifiers.id'.freeze

    # returns the resources that are currently in a curation state you specify (not looking at obsolete states),
    # ie last state for each resource.  Also returns resources (regardless of curation state) that the user can
    # see due to special privileges:
    #  - resources owned by this user_id
    #  - if tenant is specified, resources associated with the tenant
    #  - if one or more journal_issns are specified, resources associated with the journal(s)
    scope :with_visibility, ->(states:, journal_issns: nil, user_id: nil, tenant_id: nil) do
      my_states = (states.is_a?(String) || states.is_a?(Symbol) ? [states] : states)
      str = 'stash_engine_curation_activities.status IN (?)'
      arr = [my_states]
      if user_id
        str += ' OR stash_engine_resources.user_id = ?'
        arr.push(user_id)
      end
      if tenant_id
        str += ' OR stash_engine_resources.tenant_id = ?'
        arr.push(tenant_id)
      end
      if journal_issns.present?
        str += " OR (stash_engine_internal_data.data_type = 'publicationISSN' AND stash_engine_internal_data.value IN (?))"
        arr.push(journal_issns)
      end
      joins(JOIN_FOR_LATEST_CURATION).joins(JOIN_FOR_INTERNAL_DATA).distinct.where(str, *arr)
    end

    scope :visible_to_user, ->(user:) do
      if user.nil?
        with_visibility(states: %w[published embargoed])
      elsif user.superuser?
        all
      else
        tenant_admin = (user.tenant_id if user.role == 'admin')
        with_visibility(states: %w[published embargoed],
                        tenant_id: tenant_admin,
                        journal_issns: user.journals_as_admin.map(&:issn),
                        user_id: user.id)
      end
    end

    # gets the latest version per dataset and includes items that haven't been assigned an identifer yet but are initially in progress
    # NOTE.  We've now changed it so everything gets an identifier upon creation, so we may be able to simplify or get rid of this.
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

    # ---------
    # software file utility methods

    def self.software_upload_dir_for(resource_id)
      File.join(uploads_dir, "#{resource_id}_sfw")
    end

    def software_upload_dir
      Resource.software_upload_dir_for(id)
    end

    # tells whether software uploaded to zenodo for this resource has been published or not
    def software_published?
      zc = zenodo_copies.where(copy_type: 'software_publish', state: 'finished')
      zc.count.positive?
    end

    def software_submitted?
      zc = zenodo_copies.where(copy_type: 'software', state: 'finished')
      zc.count.positive?
    end

    # gets the latest files that are not deleted in db, current files for this version
    def current_file_uploads(my_class: StashEngine::FileUpload)
      subquery = my_class.where(resource_id: id).where("file_state <> 'deleted' AND " \
                                         '(url IS NULL OR (url IS NOT NULL AND status_code = 200))')
        .select('max(id) last_id, upload_file_name').group(:upload_file_name)
      my_class.joins("INNER JOIN (#{subquery.to_sql}) sub on id = sub.last_id").order(upload_file_name: :asc)
    end

    # gets new files in this version
    def new_file_uploads
      subquery = FileUpload.where(resource_id: id).where("file_state = 'created'")
        .select('max(id) last_id, upload_file_name').group(:upload_file_name)
      FileUpload.joins("INNER JOIN (#{subquery.to_sql}) sub on id = sub.last_id").order(upload_file_name: :asc)
    end

    # the states of the latest files of the same name in the resource (version), included deleted
    def latest_file_states(model: 'StashEngine::FileUpload')
      my_model = model.constantize
      subquery = my_model.where(resource_id: id)
        .select('max(id) last_id, upload_file_name').group(:upload_file_name)
      my_model.joins("INNER JOIN (#{subquery.to_sql}) sub on id = sub.last_id").order(upload_file_name: :asc)
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
    def upload_type(method: 'file_uploads')
      return :manifest if send(method).newly_created.url_submission.count > 0
      return :files if send(method).newly_created.file_submission.count > 0

      :unknown
    end

    # returns the list of fileuploads with duplicate names in created state where we shouldn't have any
    def duplicate_filenames(method: 'file_uploads')
      table_name = (method == 'file_uploads' ? 'stash_engine_file_uploads' : 'stash_engine_software_uploads')
      sql = <<-SQL
        SELECT *
        FROM #{table_name} AS a
        JOIN (SELECT upload_file_name
          FROM #{table_name}
          WHERE resource_id = ? AND (file_state IS NULL OR file_state = 'created')
          GROUP BY upload_file_name HAVING count(*) >= 2) AS b
        ON a.upload_file_name = b.upload_file_name
        WHERE a.resource_id = ?
      SQL
      # get the correct ActiveRecord model based on the method name
      "StashEngine::#{method.to_s.singularize.camelize}".constantize.find_by_sql([sql, id, id])
    end

    def url_in_version?(url)
      file_uploads.where(url: url).where(file_state: 'created').where(status_code: 200).count > 0
    end

    def files_unchanged?
      !files_changed?
    end

    def files_changed?
      file_uploads.where(file_state: %w[created deleted]).count.positive?
    end

    def software_unchanged?
      !software_changed?
    end

    def software_changed?
      software_uploads.where(file_state: %w[created deleted]).count.positive?
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

    def current_state
      current_resource_state && current_resource_state.resource_state
    end

    def current_state=(value)
      return if value == current_state

      my_state = current_resource_state
      raise "current_resource_state not initialized for resource #{id}" unless my_state

      # If the value is :submitted we need to prepare the resource for curation
      prepare_for_curation if value == 'submitted' && !preserve_curation_status?
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
      (submitted? && !files_published?) || current_curation_activity.embargoed?
    end

    def current_curation_activity
      curation_activities.order(:id).last
    end

    # Shortcut to the current curation activity's status
    def current_curation_status
      current_curation_activity.status
    end

    # Create the initial CurationActivity
    def init_curation_status
      curation_activities << StashEngine::CurationActivity.new(user_id: current_editor_id || user_id)
    end
    private :init_curation_status

    # ------------------------------------------------------------
    # Calculated dates

    # Date on which the user first submitted this dataset
    def submitted_date
      curation_activities.order(:id).where("status = 'submitted' OR status = 'peer_review'")&.first&.created_at
    end

    # Date on which the curators first received this dataset
    # (for peer_review datasets, the date at which it came out of peer_review)
    def curation_start_date
      curation_activities.order(:id).where("status = 'submitted' OR status = 'curation'")&.first&.created_at
    end

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

    def previous_resource
      StashEngine::Resource.where(identifier_id: identifier_id).where('id < ?', id).order(id: :desc).first
    end

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

    def admin_for_this_item?(user: nil)
      return false if user.nil?

      user.superuser? ||
        user_id == user.id ||
        (user.tenant_id == tenant_id && user.role == 'tenant_curator') ||
        (user.tenant_id == tenant_id && user.role == 'admin') ||
        user.journals_as_admin.include?(identifier&.journal) ||
        (user.journals_as_admin.present? && identifier&.journal.blank?)
    end

    # have the permission to edit
    def permission_to_edit?(user:)
      return false unless user

      # superuser, dataset owner or admin for the same tenant
      admin_for_this_item?(user: user)
    end

    # Checks if someone may download files for this resource
    # 1. Merritt's status, resource_state = 'submitted', meaning they are available to download from Merritt
    # 2. Curation state of files_public? means anyone may download
    # 3. if not public then users with admin privileges over the item can still download
    # Note: the special download links mean anyone with that link may download and this doesn't apply
    def may_download?(ui_user: nil) # doing this to avoid collision with the association called user
      return false unless current_resource_state&.resource_state == 'submitted' # is available in Merritt
      return true if files_published? # published and this one available for download
      return false if ui_user.blank? # the rest of the cases require users

      admin_for_this_item?(user: ui_user)
    end

    # see if the user may view based on curation status & roles and etc.  I don't see this as being particularly complex for Rubocop
    def may_view?(ui_user: nil)
      return true if metadata_published? # anyone can view
      return false if ui_user.blank? # otherwise unknown person can't view and this prevents later nil checks

      admin_for_this_item?(user: ui_user)
    end

    # ------------------------------------------------------------
    # Usage and statistics

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

    # TODO: Move this to the Author model as `Author.from_user` perhaps so that we do not need to comingle
    # StashDatacite objects directly here.
    # rubocop:disable Metrics/AbcSize
    def fill_author_from_user!
      f_name = user.first_name
      l_name = user.last_name
      orcid = (user.orcid.blank? ? nil : user.orcid)
      email = user.email

      # TODO: This probably belongs somewhere else, but without it here, the affiliation sometimes doesn't exist
      StashDatacite::AuthorPatch.patch! unless StashEngine::Author.method_defined?(:affiliation)

      affiliation = user.affiliation
      affiliation = StashDatacite::Affiliation.from_long_name(long_name: user.tenant.long_name) if affiliation.blank? &&
        user.tenant.present? && !%w[dryad localhost].include?(user.tenant.abbreviation.downcase)
      StashEngine::Author.create(resource_id: id, author_orcid: orcid, affiliation: affiliation,
                                 author_first_name: f_name, author_last_name: l_name, author_email: email)
      # disabling because we no longer wnat this with UC Press
      # author.affiliation_by_name(user.tenant.short_name) if user.try(:tenant)
    end
    # rubocop:enable Metrics/AbcSize

    # -----------------------------------------------------------
    # Publication
    def files_published?
      identifier&.pub_state == 'published' && file_view == true
    end

    # Metadata is published when the curator sets the status to published or embargoed
    def metadata_published?
      %w[published embargoed].include?(identifier&.pub_state) && meta_view == true
    end

    # this is a query for the publication updating on a cron, but putting here so we can test the query more easily
    def self.need_publishing
      # submitted to merritt, curation embargoed, past publication date
      all.submitted.with_visibility(states: %w[embargoed]).where('stash_engine_resources.publication_date < ?', Time.now)
    end

    # -----------------------------------------------------------
    # editor

    # gets the in progress editor, if any, for the whole dataset
    # nil means no in progress dataset or the owner is the one in progress
    def dataset_in_progress_editor_id
      # no identifier, has to be in progress
      return current_editor_id if identifier.nil?
      return identifier.in_progress_resource.current_editor_id if identifier.in_progress? && identifier.in_progress_resource.present?

      nil
    end

    # calculated current editor name, ignores nil current editor as current logged in user
    def dataset_in_progress_editor
      return user if dataset_in_progress_editor_id.nil?

      User.where(id: dataset_in_progress_editor_id).first
    end

    # -----------------------------------------------------------
    # Title

    # Title without "Data from:"
    def clean_title
      title.delete_prefix('Data from:').strip
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

    def send_to_zenodo
      return if file_uploads.empty? # no files? Then don't send to Zenodo for duplication.

      ZenodoCopy.create(state: 'enqueued', identifier_id: identifier_id, resource_id: id, copy_type: 'data') if zenodo_copies.data.empty?
      ZenodoCopyJob.perform_later(id)
    end

    # if publish: true then it just publishes, which is a separate operation than updating files
    def send_software_to_zenodo(publish: false)
      return unless identifier.has_zenodo_software?

      rep_type = (publish == true ? 'software_publish' : 'software')
      return if ZenodoCopy.where(resource_id: id, copy_type: rep_type).count.positive? # don't add again if it's already sent

      zc = ZenodoCopy.create(state: 'enqueued', identifier_id: identifier_id, resource_id: id, copy_type: rep_type)
      ZenodoSoftwareJob.perform_later(zc.id)
    end

    # type can currently be data, software or supplemental
    ALLOWED_UPLOAD_TYPES = { base: '', data: '/data', software: '/sfw',
                             supplemental: '/supp', manifest: '/manifest' }.with_indifferent_access.freeze

    # this is long and wonky because it creates unique bucket "directories" even if running multiple different
    # development environments on either different servers or against different databases (local or not local)
    def s3_dir_name(type: 'data')
      raise 'Error, incorrect upload type' if ALLOWED_UPLOAD_TYPES[type].nil?
      return "#{id}#{ALLOWED_UPLOAD_TYPES[type]}" if %w[production stage].include?(Rails.env)

      db_host = Rails.configuration.database_configuration[Rails.env]['host']
      if db_host.include?('localhost') || db_host.include?('127.0.0.1')
        d = Digest::MD5.hexdigest("host-#{`hostname`.strip}")[0..7] # shorten to make less verbose for small number of servers
        return "#{d}-#{id}#{ALLOWED_UPLOAD_TYPES[type]}"
      end
      d = Digest::MD5.hexdigest("db-#{db_host.strip}")[0..7]
      "#{d}-#{id}#{ALLOWED_UPLOAD_TYPES[type]}"
    end

    private

    # -----------------------------------------------------------
    # Handle the 'submitted' state (happens after successful Merritt submission)
    def prepare_for_curation
      # gets last resource
      prior_version = identifier.resources.includes(:curation_activities).where.not(id: id).order(created_at: :desc).first if identifier.present?

      # try to assign the same person as immediately previous activity, otherwise prefer editor_id and then user_id from resource
      cur_act = StashEngine::CurationActivity.joins(:resource).where('stash_engine_resources.identifier_id = ?', identifier_id)
        .order(id: :desc).first
      attribution = (cur_act.nil? ? (current_editor_id || user_id) : cur_act.user_id)
      curation_to_submitted(prior_version, attribution)
    end

    def curation_to_submitted(prior_version, attribution)
      # Determine which submission status to use, :submitted or :peer_review status (if this is the inital
      # version and the journal needs it)
      status = (hold_for_peer_review? ? 'peer_review' : 'submitted')

      # Generate the :submitted status
      # This will usually have the side effect of sending out notification emails to the author/journal
      curation_activities << StashEngine::CurationActivity.create(user_id: attribution, status: status)
      curation_to_curation(prior_version) unless prior_version.blank?
    end

    def curation_to_curation(prior_version)
      return if prior_version.blank? || prior_version.current_curation_status.blank?
      # If the prior version was in author :action_required or :curation status we need to set it
      # back to :curation status. Also carry over the curators note so that it appears in the activity log
      return unless %w[action_required curation].include?(prior_version.current_curation_status)

      curation_activities << StashEngine::CurationActivity.create(user_id: 0, status: 'curation',
                                                                  note: 'system set back to curation')
    end
  end
end
