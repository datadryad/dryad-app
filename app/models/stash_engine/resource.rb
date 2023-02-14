require 'stash/aws/s3'
# require 'stash/indexer/indexing_resource'
require 'stash/indexer/solr_indexer'
# the following is required to make our wonky tests work and may break if we move stuff around
require_relative '../../../lib/stash/indexer/indexing_resource'

module StashEngine
  class Resource < ApplicationRecord # rubocop:disable Metrics/ClassLength
    self.table_name = 'stash_engine_resources'
    # ------------------------------------------------------------
    # Relations

    has_many :authors, class_name: 'StashEngine::Author', dependent: :destroy
    has_many :generic_files, class_name: 'StashEngine::GenericFile', dependent: :destroy
    has_many :data_files, class_name: 'StashEngine::DataFile', dependent: :destroy
    has_many :software_files, class_name: 'StashEngine::SoftwareFile', dependent: :destroy
    has_many :supp_files, class_name: 'StashEngine::SuppFile', dependent: :destroy
    has_many :edit_histories, class_name: 'StashEngine::EditHistory'
    has_one :stash_version, class_name: 'StashEngine::Version', dependent: :destroy
    belongs_to :identifier, class_name: 'StashEngine::Identifier', foreign_key: 'identifier_id'
    belongs_to :user, class_name: 'StashEngine::User'
    has_one :current_resource_state,
            class_name: 'StashEngine::ResourceState',
            primary_key: 'current_resource_state_id',
            foreign_key: 'id'
    has_one :last_curation_activity,
            class_name: 'StashEngine::CurationActivity',
            primary_key: 'last_curation_activity_id',
            foreign_key: 'id'
    has_one :editor, class_name: 'StashEngine::User', primary_key: 'current_editor_id', foreign_key: 'id'
    has_many :submission_logs, class_name: 'StashEngine::SubmissionLog', dependent: :destroy
    has_many :resource_states, class_name: 'StashEngine::ResourceState', dependent: :destroy
    has_many :edit_histories, class_name: 'StashEngine::EditHistory', dependent: :destroy
    has_many :curation_activities, -> { order(id: :asc) }, class_name: 'StashEngine::CurationActivity', dependent: :destroy
    has_many :repo_queue_states, class_name: 'StashEngine::RepoQueueState', dependent: :destroy
    has_many :zenodo_copies, class_name: 'StashEngine::ZenodoCopy', dependent: :destroy
    # download tokens are for Merritt version downloads with presigned URL caching
    has_one :download_token, class_name: 'StashEngine::DownloadToken', dependent: :destroy
    has_many :publication_years, class_name: 'StashDatacite::PublicationYear', dependent: :destroy
    has_one :publisher, class_name: 'StashDatacite::Publisher', dependent: :destroy
    has_one :language, class_name: 'StashDatacite::Language', dependent: :destroy
    has_many :descriptions, class_name: 'StashDatacite::Description', dependent: :destroy
    has_many :contributors, class_name: 'StashDatacite::Contributor', dependent: :destroy
    has_many :datacite_dates, class_name: 'StashDatacite::DataciteDate', dependent: :destroy
    has_many :descriptions, class_name: 'StashDatacite::Description', dependent: :destroy
    has_many :geolocations, class_name: 'StashDatacite::Geolocation', dependent: :destroy
    has_many :temporal_coverages, class_name: 'StashDatacite::TemporalCoverage', dependent: :destroy
    has_many :related_identifiers, class_name: 'StashDatacite::RelatedIdentifier', dependent: :destroy
    has_one :resource_type, class_name: 'StashDatacite::ResourceType', dependent: :destroy
    has_many :rights, class_name: 'StashDatacite::Right', dependent: :destroy
    has_many :sizes, class_name: 'StashDatacite::Size', dependent: :destroy
    has_and_belongs_to_many :subjects, class_name: 'StashDatacite::Subject', through: 'StashDatacite::ResourceSubject', dependent: :destroy
    has_many :alternate_identifiers, class_name: 'StashDatacite::AlternateIdentifier', dependent: :destroy
    has_many :formats, class_name: 'StashDatacite::Format', dependent: :destroy
    has_one :version, class_name: 'StashDatacite::Version', dependent: :destroy
    has_many :processor_results, class_name: 'StashEngine::ProcessorResult', dependent: :destroy

    # self.class.reflect_on_all_associations(:has_many).select{ |i| i.name.to_s.include?('file') }.map{ |i| [i.name, i.class_name] }
    ASSOC_TO_FILE_CLASS = reflect_on_all_associations(:has_many).select { |i| i.name.to_s.include?('file') }
      .to_h { |i| [i.name, i.class_name] }.with_indifferent_access.freeze

    accepts_nested_attributes_for :curation_activities

    # ensures there is always an associated download_token record
    def download_token
      super || build_download_token(token: nil, available: nil)
    end

    amoeba do
      include_association :authors
      include_association :generic_files
      customize(->(_, new_resource) do
                  # you'd think 'include_association :current_resource_state' would do the right thing and deep-copy
                  # the resource state, but instead it keeps the reference to the old one, so we need to clear it and
                  # let init_version do its job
                  new_resource.current_resource_state_id = nil
                  # do not mark these resources for public view until they've been re-curated and embargoed/published again
                  new_resource.meta_view = false
                  new_resource.file_view = false

                  new_resource.generic_files.each do |file|
                    raise "Expected #{new_resource.id}, was #{file.resource_id}" unless file.resource_id == new_resource.id

                    if file.file_state == 'created'
                      file.file_state = 'copied'
                      file.save
                    end
                  end

                  # I think there was something weird about Amoeba that required this approach
                  deleted_files = new_resource.generic_files.select { |ar_record| ar_record.file_state == 'deleted' }
                  deleted_files.each(&:destroy)
                end)

      # can't just pass the array to include_association() or it clobbers the ones defined in stash_engine
      # see https://github.com/amoeba-rb/amoeba/issues/76
      %i[contributors datacite_dates descriptions geolocations temporal_coverages
         publication_years publisher related_identifiers resource_type rights sizes
         subjects].each do |assoc|
        include_association assoc
      end
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

    after_create :init_state_and_version
    # for some reason, after_create not working, so had to add after_update
    before_destroy :remove_s3_temp_files
    after_destroy :remove_identifier_with_no_resources

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

    scope :with_public_metadata, -> do
      where(meta_view: true)
    end

    scope :files_published, -> do
      # this also depends on the publication updater to update statuses to published daily
      where(file_view: true)
    end

    # this is METADATA published
    scope :published, -> do
      joins(:last_curation_activity).where("stash_engine_curation_activities.status IN ('published', 'embargoed')")
        .where('stash_engine_resources.publication_date < ?', Time.now.utc)
    end

    JOIN_FOR_INTERNAL_DATA = 'INNER JOIN stash_engine_identifiers ON stash_engine_identifiers.id = stash_engine_resources.identifier_id ' \
                             'LEFT OUTER JOIN stash_engine_internal_data ' \
                             'ON stash_engine_internal_data.identifier_id = stash_engine_identifiers.id'.freeze

    JOIN_FOR_CONTRIBUTORS = 'LEFT OUTER JOIN dcs_contributors ON stash_engine_resources.id = dcs_contributors.resource_id'.freeze

    # returns the resources that are currently in a curation state you specify (not looking at obsolete states),
    # ie last state for each resource.  Also returns resources (regardless of curation state) that the user can
    # see due to special privileges:
    #  - resources owned by this user_id
    #  - if tenant is specified, resources associated with the tenant
    #  - if one or more journal_issns are specified, resources associated with the journal(s)
    #  - if one or more funder_ids are specified, resources associated with the funder(s)
    scope :with_visibility, ->(states:, journal_issns: nil, funder_ids: nil, user_id: nil, tenant_id: nil) do
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
      if funder_ids.present?
        str += " OR (dcs_contributors.contributor_type = 'funder' AND dcs_contributors.name_identifier_id IN (?))"
        arr.push(funder_ids)
      end
      joins(:last_curation_activity).joins(JOIN_FOR_INTERNAL_DATA).joins(JOIN_FOR_CONTRIBUTORS).distinct.where(str, *arr)
    end

    scope :visible_to_user, ->(user:) do
      if user.nil?
        with_visibility(states: %w[published embargoed])
      elsif user.limited_curator?
        all
      else
        tenant_admin = (user.tenant_id if user.role == 'admin')
        with_visibility(states: %w[published embargoed],
                        tenant_id: tenant_admin,
                        funder_ids: user.funders_as_admin.map(&:funder_id),
                        journal_issns: user.journals_as_admin.map(&:single_issn),
                        user_id: user.id)
      end
    end

    # limits to the latest resource for each dataset if added to resources
    scope :latest_per_dataset, (-> do
      joins('INNER JOIN stash_engine_identifiers ON stash_engine_resources.id = stash_engine_identifiers.latest_resource_id')
    end)

    # ------------------------------------------------------------
    # File upload utility methods
    # TODO: these are obsolete, but we will want to remove Stash::Merritt::Sword classes at the same time that rely
    # on direct file uploads when we do further cleanup of the Merritt classes.  May also deprecate all current Merritt
    # classes if they offer a better API than SWORD.

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

    # tells whether software uploaded to zenodo for this resource has been published or not
    # types are software or supp
    def zenodo_published?(type: 'software')
      zc = zenodo_copies.where(copy_type: "#{type}_publish", state: 'finished')
      zc.count.positive?
    end

    def zenodo_submitted?(type: 'software')
      zc = zenodo_copies.where(copy_type: type, state: 'finished')
      zc.count.positive?
    end

    # gets the latest files that are not deleted in db, current files for this version
    def current_file_uploads(my_class: StashEngine::DataFile)
      subquery = my_class.where(resource_id: id).where("file_state <> 'deleted' AND " \
                                                       '(url IS NULL OR (url IS NOT NULL AND status_code = 200))')
        .select('max(id) last_id, upload_file_name').group(:upload_file_name)
      my_class.joins("INNER JOIN (#{subquery.to_sql}) sub on id = sub.last_id").order(upload_file_name: :asc)
    end

    # gets new files in this version
    def new_data_files
      subquery = DataFile.where(resource_id: id).where("file_state = 'created'")
        .select('max(id) last_id, upload_file_name').group(:upload_file_name)
      DataFile.joins("INNER JOIN (#{subquery.to_sql}) sub on id = sub.last_id").order(upload_file_name: :asc)
    end

    # the states of the latest files of the same name in the resource (version), included deleted
    def latest_file_states(model: 'StashEngine::DataFile')
      my_model = model.constantize
      subquery = my_model.where(resource_id: id)
        .select('max(id) last_id, upload_file_name').group(:upload_file_name)
      my_model.joins("INNER JOIN (#{subquery.to_sql}) sub on id = sub.last_id").order(upload_file_name: :asc)
    end

    # the size of this resource (created + copied files)
    def size(association: 'data_files')
      public_send(association.intern).where(file_state: %w[copied created]).sum(:upload_file_size)
    end

    # just the size of the new files
    def new_size(association: 'data_files')
      public_send(association.intern).where(file_state: %w[created]).sum(:upload_file_size)
    end

    # returns the upload type either :files, :manifest, :unknown (unknown if no files are started for this version yet)
    def upload_type(association: 'data_files')
      return :manifest if send(association).newly_created.url_submission.count > 0
      return :files if send(association).newly_created.file_submission.count > 0

      :unknown
    end

    # returns the list of files with duplicate names in created state where we shouldn't have any
    def duplicate_filenames(association: 'data_files')
      target_class_name = ASSOC_TO_FILE_CLASS[association]
      raise 'Invalid table name' if target_class_name.blank?

      sql = <<-SQL
        SELECT *
        FROM stash_engine_generic_files AS a
        JOIN (SELECT upload_file_name
          FROM stash_engine_generic_files
          WHERE resource_id = ? AND (file_state IS NULL OR file_state = 'created') AND type = ?
          GROUP BY upload_file_name HAVING count(*) >= 2) AS b
        ON a.upload_file_name = b.upload_file_name
        WHERE a.resource_id = ? AND type = ?
      SQL
      # get the correct ActiveRecord model based on the method name
      target_class_name.constantize.find_by_sql([sql, id, target_class_name, id, target_class_name])
    end

    def url_in_version?(url:, association: 'data_files')
      send(association).where(url: url).where(file_state: 'created').where(status_code: 200).count > 0
    end

    def files_unchanged?(association: 'data_files')
      !files_changed?(association: association)
    end

    def files_changed?(association: 'data_files')
      send(association).where(file_state: %w[created deleted]).count.positive?
    end

    def files_changed_since(other_resource:, association: 'data_files')
      return [] unless other_resource

      resources = StashEngine::Resource.where(identifier_id: identifier_id)
        .where('id <= ? AND id > ?', id, other_resource.id).order(id: :desc)
      result = []
      resources.each do |r|
        result << r.send(association).where(file_state: %w[created deleted])
      end

      result.flatten
    end

    # We create one of some editing items that aren't required and might not be filled in.  Also users may add a blank
    # item and then never fill anything in.  This cleans up those items.  Probably useful in the review page.
    def cleanup_blank_models!
      related_identifiers.where("related_identifier is NULL or related_identifier = ''").destroy_all # no id? this related item is blank
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
      (submitted? && !files_published?) || last_curation_activity&.embargoed?
    end

    # Shortcut to the current curation activity's status
    def current_curation_status
      reload
      last_curation_activity&.status
    end

    # Create the initial CurationActivity
    def init_curation_status
      curation_activities << StashEngine::CurationActivity.new(user_id: current_editor_id || user_id)
    end
    private :init_curation_status

    # ------------------------------------------------------------
    # Calculated dates

    # Date on which the user first submitted this resource
    def submitted_date
      curation_activities.order(:id).where("status = 'submitted' OR status = 'peer_review'")&.first&.created_at
    end

    # Date on which the curators first received this resource
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

    def previous_curated_resource
      StashEngine::Resource.joins(:last_curation_activity)
        .where("stash_engine_curation_activities.status IN ('published', 'embargoed', 'action_required')")
        .where(identifier_id: identifier_id).where('stash_engine_resources.id < ?', id)
        .order(id: :desc).first
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
      # only curators and above (not limited curators) have permission to edit
      permission_to_edit?(user: user) && (dataset_in_progress_editor.id == user.id || user.curator?)
    end

    def admin_for_this_item?(user: nil)
      return false if user.nil?

      user.limited_curator? ||
        user_id == user.id ||
        (user.tenant_id == tenant_id && user.role == 'admin') ||
        funders_match?(user: user) ||
        user.journals_as_admin.include?(identifier&.journal) ||
        (user.journals_as_admin.present? && identifier&.journal.blank?)
    end

    def funders_match?(user:)
      user_funders = user.funders_as_admin
      resource_funders = contributors
      return unless user_funders.present? && resource_funders.present?

      user_funder_ids = user_funders.map(&:funder_id).compact.reject(&:empty?)
      resource_funder_ids = resource_funders.map(&:name_identifier_id).compact.reject(&:empty?)
      user_funder_ids.&(resource_funder_ids).present?
    end

    # have the permission to edit
    def permission_to_edit?(user:)
      return false unless user

      # cuartor, dataset owner or admin for the same tenant
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

    # may not be able to match one up
    def owner_author
      return nil unless user&.orcid.present? # apparently there are cases where user doesn't have an orcid

      authors.where(author_orcid: user.orcid).first
    end

    def fill_blank_author!
      return if authors.count > 0 || user.blank? # already has some authors filled in or no user to know about

      fill_author_from_user!
    end

    # TODO: Move this to the Author model as `Author.from_user` perhaps so that we do not need to comingle
    # StashDatacite objects directly here.
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

    # returns boolean indicating if a version before the current resource has been made public (metadata view set to true)
    def previously_public?
      prev = self.class.where(identifier_id: identifier_id).where('created_at < ?', created_at).where(meta_view: true)
      prev.count.positive?
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

    # this just sends a **COPY** job to zenodo (ie Merritt duplication), not for replication which could be sfw or supp
    def send_to_zenodo(note: nil)
      return if data_files.empty? # no files? Then don't send to Zenodo for duplication.

      existing_copy = zenodo_copies.data.first
      if existing_copy.nil?
        existing_copy = ZenodoCopy.create(state: 'enqueued', identifier_id: identifier_id, resource_id: id, copy_type: 'data', note: note)
      end

      ZenodoCopyJob.perform_later(id) if existing_copy.state == 'enqueued'
    end

    # if publish: true then it just publishes, which is a separate operation than updating files
    def send_software_to_zenodo(publish: false)
      return unless identifier.has_zenodo_software?

      rep_type = (publish == true ? 'software_publish' : 'software')
      return if ZenodoCopy.where(resource_id: id, copy_type: rep_type).count.positive? # don't add again if it's already sent

      zc = ZenodoCopy.create(state: 'enqueued', identifier_id: identifier_id, resource_id: id, copy_type: rep_type)
      ZenodoSoftwareJob.perform_later(zc.id)
    end

    # if publish: true then it just publishes, which is a separate operation than updating files
    def send_supp_to_zenodo(publish: false)
      return unless identifier.has_zenodo_supp?

      rep_type = (publish == true ? 'supp_publish' : 'supp')
      return if ZenodoCopy.where(resource_id: id, copy_type: rep_type).count.positive? # don't add again if it's already sent

      zc = ZenodoCopy.create(state: 'enqueued', identifier_id: identifier_id, resource_id: id, copy_type: rep_type)
      ZenodoSuppJob.perform_later(zc.id)
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

    # Changes since the previously curated version
    def changed_from_previous_curated
      changed_fields(previous_curated_resource)
    end

    # Yes, this method looks complex,
    # but breaking it into a bunch of smaller methods would only make it seem more complex
    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def changed_fields(other_resource)
      return [] unless other_resource

      changed = []

      changed << 'title' if title != other_resource.title

      this_auth_string = authors.map { |c| c.author_full_name unless c.author_full_name =~ /^[ ,]+$/ }.compact.to_s
      that_auth_string = other_resource.authors.map { |c| c.author_full_name unless c.author_full_name =~ /^[ ,]+$/ }.compact.to_s
      changed << 'authors' if this_auth_string != that_auth_string

      this_facility = contributors.where(contributor_type: 'sponsor').first&.contributor_name
      that_facility = other_resource.contributors.where(contributor_type: 'sponsor').first&.contributor_name
      changed << 'facility' if this_facility != that_facility

      this_abstract = descriptions.type_abstract.map(&:description)
      that_abstract = other_resource.descriptions.type_abstract.map(&:description)
      changed << 'abstract' if this_abstract != that_abstract

      this_methods = descriptions.type_methods.map(&:description)
      that_methods = other_resource.descriptions.type_methods.map(&:description)
      changed << 'methods' if this_methods != that_methods

      this_other_desc = descriptions.type_other.map(&:description)
      that_other_desc = other_resource.descriptions.type_other.map(&:description)
      changed << 'usage_notes' if this_other_desc != that_other_desc

      changed << 'subjects' if subjects.map(&:subject).to_s != other_resource.subjects.map(&:subject).to_s

      this_funders = contributors.where(contributor_type: 'funder').map { |c| "#{c.contributor_name} #{c.award_number}" }.to_s
      that_funders = other_resource.contributors.where(contributor_type: 'funder').map { |c| "#{c.contributor_name} #{c.award_number}" }.to_s
      changed << 'funders' if this_funders != that_funders

      this_related = related_identifiers.map { |r| "#{r.related_identifier} #{r.work_type}" }.to_s
      that_related = other_resource.related_identifiers.map { |r| "#{r.related_identifier} #{r.work_type}" }.to_s
      changed << 'related_identifiers' if this_related != that_related

      changed << 'data_files' if files_changed_since(other_resource: other_resource, association: 'data_files').present?
      changed << 'software_files' if files_changed_since(other_resource: other_resource, association: 'software_files').present?
      changed << 'supp_files' if files_changed_since(other_resource: other_resource, association: 'supp_files').present?

      changed
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def update_salesforce_metadata
      sf_cases = Stash::Salesforce.find_cases_by_doi(identifier&.identifier)
      sf_cases&.each do |c|
        Stash::Salesforce.update_case_metadata(case_id: c.id, resource: self, update_timestamp: true)
      end
    end

    private

    # -----------------------------------------------------------
    # Handle the 'submitted' resource state (happens after successful Merritt submission)
    # rubocop:disable Metrics/AbcSize
    def prepare_for_curation
      prior_version = identifier.resources.includes(:curation_activities).where.not(id: id).order(created_at: :desc).first if identifier.present?

      # try to assign credit for the action to the same person as the immediately previous activity,
      # otherwise prefer editor_id and then user_id from resource
      prior_cur_act = StashEngine::CurationActivity.joins(:resource).where('stash_engine_resources.identifier_id = ?', identifier_id)
        .order(id: :desc).first

      target_status = create_post_submission_status(prior_cur_act)

      # Warn curators if this is potentially a duplicate
      completions = StashDatacite::Resource::Completions.new(self)
      if prior_version.blank? && completions.duplicate_submission
        dup_id = completions.duplicate_submission.identifier&.identifier
        curation_activities << StashEngine::CurationActivity.create(user_id: 0, status: target_status,
                                                                    note: "System noticed possible duplicate dataset #{dup_id}")
      end

      # if it's the first version, or the prior version was in the submitter's control, we're done
      return if prior_version.blank? || prior_version.current_curation_status.blank?
      return unless identifier.date_last_curated.present?

      # If we get here, the previous status was *not* controlled by the submitter,
      # meaning there was a curator
      # so assign it to the previous curator, with a fallback process
      auto_assign_curator(target_status: target_status)

      # If it has never been published,
      # OR it has been in curation more recently than the last published version,
      # OR the last user to edit it was the current_editor
      # return it to curation status
      return unless identifier.date_last_published.blank? ||
                    identifier.date_last_curated > identifier.date_last_published ||
                    last_curation_activity.user_id == current_editor_id

      curation_activities << StashEngine::CurationActivity.create(user_id: 0, status: 'curation',
                                                                  note: 'System set back to curation')
    end
    # rubocop:enable Metrics/AbcSize

    def create_post_submission_status(prior_cur_act)
      attribution = (prior_cur_act.nil? ? (current_editor_id || user_id) : prior_cur_act.user_id)
      # Determine which submission status to use, :submitted or :peer_review status
      publication_accepted = identifier.has_accepted_manuscript? || identifier.publication_article_doi
      if hold_for_peer_review?
        # Moving this logic to user facing, will not allow PPR selection by user
        if publication_accepted
          manuscript = identifier.manuscript_number || identifier.publication_article_doi
          curation_note = "Private for peer review was requested, but associated manuscript #{manuscript} has " \
                          'already been accepted, so automatically moving to submitted status'
          target_status = 'submitted'
        else
          curation_note = "Set to Private for peer review at author's request"
          target_status = 'peer_review'
        end
      else
        curation_note = ''
        target_status = 'submitted'
      end

      # Generate the :submitted or :peer_review status
      # This will usually have the side effect of sending out notification emails to the author/journal
      curation_activities << StashEngine::CurationActivity.create(user_id: attribution, status: target_status, note: curation_note)
      target_status
    end

    def auto_assign_curator(target_status:)
      target_curator = identifier.most_recent_curator
      if target_curator.nil? || !target_curator.curator?
        # if the previous curator does not exist, or is no longer a curator,
        # set it to a random current curator , but not a superuser
        cur_list = StashEngine::User.where(role: 'curator').to_a
        target_curator = cur_list[rand(cur_list.length)]
      end

      return unless target_curator

      update(current_editor_id: target_curator.id)
      curation_activities << StashEngine::CurationActivity.create(user_id: 0, status: target_status,
                                                                  note: "System auto-assigned curator #{target_curator&.name}")
    end
  end
end
