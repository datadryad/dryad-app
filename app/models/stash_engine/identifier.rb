# == Schema Information
#
# Table name: stash_engine_identifiers
#
#  id                      :integer          not null, primary key
#  deleted_at              :datetime
#  edit_code               :string(191)
#  identifier              :text(65535)
#  identifier_type         :text(65535)
#  import_info             :integer
#  last_invoiced_file_size :bigint
#  old_payment_system      :boolean          default(FALSE)
#  payment_type            :string(191)
#  pub_state               :string
#  publication_date        :datetime
#  search_words            :text(65535)
#  storage_size            :bigint
#  waiver_basis            :string(191)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  latest_resource_id      :integer
#  license_id              :string(191)
#  payment_id              :text(65535)
#  software_license_id     :integer
#
# Indexes
#
#  admin_search_index                                     (search_words)
#  index_stash_engine_identifiers_on_deleted_at           (deleted_at)
#  index_stash_engine_identifiers_on_identifier           (identifier)
#  index_stash_engine_identifiers_on_latest_resource_id   (latest_resource_id)
#  index_stash_engine_identifiers_on_license_id           (license_id)
#  index_stash_engine_identifiers_on_software_license_id  (software_license_id)
#
require 'httparty'
require 'http'

module StashEngine
  # rubocop:disable Metrics/ClassLength
  class Identifier < ApplicationRecord
    include StashEngine::Support::PaymentMethods
    include StashEngine::Support::Limits

    self.table_name = 'stash_engine_identifiers'
    acts_as_paranoid
    has_paper_trail

    has_many :resources, class_name: 'StashEngine::Resource', dependent: :destroy
    has_one :process_date, as: :processable, dependent: :destroy
    has_many :orcid_invitations, class_name: 'StashEngine::OrcidInvitation', dependent: :destroy
    has_one :counter_stat, class_name: 'StashEngine::CounterStat', dependent: :destroy
    has_many :internal_data, class_name: 'StashEngine::InternalDatum', dependent: :destroy
    has_one :manuscript_datum, -> { where(data_type: 'manuscriptNumber').order(created_at: :desc).limit(1) }, class_name: 'StashEngine::InternalDatum'
    has_one :journal_datum, -> { where(data_type: 'publicationISSN').order(created_at: :desc).limit(1) }, class_name: 'StashEngine::InternalDatum'
    has_one :journal_name_datum, -> {
                                   where(data_type: 'publicationName').order(created_at: :desc).limit(1)
                                 }, class_name: 'StashEngine::InternalDatum'
    has_many :external_references, class_name: 'StashEngine::ExternalReference', dependent: :destroy
    # there are places we may have more than one from our old versions
    has_many :shares, class_name: 'StashEngine::Share', dependent: :destroy
    has_many :cached_citations, class_name: 'StashEngine::CounterCitation', dependent: :destroy
    has_many :zenodo_copies, class_name: 'StashEngine::ZenodoCopy', dependent: :destroy
    has_one :latest_resource,
            class_name: 'StashEngine::Resource',
            primary_key: 'latest_resource_id',
            foreign_key: 'id'
    belongs_to :software_license, class_name: 'StashEngine::SoftwareLicense', optional: true
    has_many :curation_activities, class_name: 'StashEngine::CurationActivity', through: :resources
    has_many :payments, class_name: 'ResourcePayment', through: :resources

    after_create :create_process_date, unless: :process_date
    after_create :create_share

    # This makes the setting of the "preliminary information" and how something was imported explicit.  Default is other.
    # There is only one import per dataset and it overwrites info after getting valid information.
    enum :import_info, {
      other: 0,
      manuscript: 1,
      published: 2,
      preprint: 3
    }

    # See https://medium.com/rubyinside/active-records-queries-tricks-2546181a98dd for some good tricks
    # returns the identifiers that have resources with that *latest* curation state you specify (for any of the resources)
    scope :with_visibility, ->(states:, journal_issns: nil, funder_ids: nil, user_id: nil, tenant_id: nil) do
      where(id: Resource.with_visibility(states: states, journal_issns: journal_issns, funder_ids: funder_ids, user_id: user_id, tenant_id: tenant_id)
                        .select('identifier_id').distinct.map(&:identifier_id))
    end

    scope :publicly_viewable, -> do
      where(pub_state: %w[published embargoed])
    end

    scope :cited_by_pubmed, -> do
      publicly_viewable.joins(:internal_data)
        .where('stash_engine_internal_data.data_type = ? AND stash_engine_internal_data.value IS NOT NULL', 'pubmedID')
        .order('stash_engine_identifiers.identifier')
    end

    scope :cited_by_external_site, ->(site) do
      publicly_viewable.joins(:external_references)
        .where('stash_engine_external_references.source = ? AND stash_engine_external_references.value IS NOT NULL', site)
        .order('stash_engine_identifiers.identifier')
    end

    # has_many :counter_citations, class_name: 'StashEngine::CounterCitation', dependent: :destroy
    # before_create :build_associations

    # used to build counter stat if needed, trickery to be sure one always exists to begin with
    # https://stackoverflow.com/questions/3808782/rails-best-practice-how-to-create-dependent-has-one-relations
    def counter_stat
      super || build_counter_stat(citation_count: 0, unique_investigation_count: 0, unique_request_count: 0,
                                  created_at: Time.new.utc - 7.days, updated_at: Time.new.utc - 7.days)
    end

    # gets citations for this identifier w/ citation class
    def citations
      CounterCitation.citations(stash_identifier: self)
    end

    # finds by an ID that is full id, not the broken apart stuff
    def self.find_with_id(full_id)
      prefix, i = CGI.unescape(full_id).split(':', 2)
      Identifier.where(identifier_type: prefix, identifier: i).try(:first)
    end

    def identifier_id
      id
    end

    def identifier_str
      "#{identifier_type && identifier_type.downcase}:#{identifier}"
    end

    def identifier_uri
      raise TypeError, "Unsupported identifier type #{identifier_type}" unless identifier_type == 'DOI'

      "https://doi.org/#{identifier}"
    end

    def identifier_value
      identifier
    end

    def view_count
      ResourceUsage.joins(resource: :identifier)
        .where('stash_engine_identifiers.identifier = ? AND stash_engine_identifiers.identifier_type = ?',
               identifier, identifier_type).sum(:views)
    end

    def download_count
      ResourceUsage.joins(resource: :identifier)
        .where('stash_engine_identifiers.identifier = ? AND stash_engine_identifiers.identifier_type = ?',
               identifier, identifier_type).sum(:downloads)
    end

    # these are items that are embargoed or published and can show metadata
    def latest_resource_with_public_metadata
      return nil if pub_state == 'withdrawn'

      resources.with_public_metadata.by_version_desc.first
    end

    # these are resources that the user can look at because of permissions, some user roles can see non-published others, not
    def latest_viewable_resource(user: nil)
      return latest_resource_with_public_metadata if user.nil?

      lr = latest_resource
      return lr if lr&.permission_to_edit?(user: user)

      latest_resource_with_public_metadata
    end

    def latest_resource_with_public_download
      resources.files_published.by_version_desc.first
    end

    def latest_downloadable_resource(user: nil)
      return latest_resource_with_public_download if user.nil?

      lr = resources.with_file_changes.submitted.last
      return lr if lr&.permission_to_edit?(user: user) && lr.version_number > (latest_resource_with_public_download&.version_number || 0)

      latest_resource_with_public_download
    end

    def may_download?(user: nil)
      !latest_downloadable_resource(user: user).blank?
    end

    def last_submitted_version_number
      (lsv = last_submitted_resource) && lsv.version_number
    end

    # this returns a resource object for the last preserved version, caching in instance variable for repeated calls
    def last_submitted_resource
      return @last_submitted_resource unless @last_submitted_resource.blank?

      submitted = resources.submitted
      @last_submitted_resource = submitted.by_version_desc.first
    end

    def first_submitted_resource
      submitted = resources.submitted
      submitted.by_version.first
    end

    def most_recent_curator
      resources.reverse.each do |r|
        next unless r.current_editor_id

        user = StashEngine::User.find_by(id: r.current_editor_id)
        return user if user&.min_curator?
      end
      nil
    end

    # @return Resource the current 'processing' resource
    def processing_resource
      processing = resources.processing
      processing.by_version_desc.first
    end

    # @return true if there's a 'processing' version
    def processing?
      resources.processing.count > 0
    end

    # return true if there's an 'error' version
    def error?
      resources.error.count > 0
    end

    def in_progress_only?
      resources.in_progress_only.count > 0
    end

    # @return Resource the current in-progress resource
    def in_progress_resource
      in_progress = resources.in_progress
      in_progress.first
    end

    # @return true if there is an in progress version
    def in_progress?
      resources.in_progress.count > 0
    end

    def to_s
      # TODO: Make sure this is correct for all identifier types
      "#{identifier_type&.downcase}:#{identifier}"
    end

    # the landing URL seems like a view component, but really it's given to people as data outside the view by way of
    # logging, APIs as a target
    #
    # also couldn't calculate this easily in the past because url had some problems with user calculations for tenant
    # but now tenant gets tied to the dataset (resource) for easier and consistent lookup of the domain.
    #
    # TODO: modify all code that calculates the target to use this method if possible/feasible.
    def target
      return @target unless @target.blank?

      r = resources.by_version_desc.first
      tenant = r.tenant
      @target = tenant.full_url(Rails.application.routes.url_helpers.show_path(to_s))
    end

    # the search words is a special MySQL search field that concatenates the following fields required to be searched over
    # https://github.com/datadryad/dryad-product-roadmap/issues/125
    # doi (from this model), latest_resource.title, latest_resource.authors (names, emails, orcids), dcs_descriptions of type abstract
    def update_search_words!
      my_string = to_s
      if latest_resource
        my_string << " #{latest_resource.title}"
        my_string << ' ' << latest_resource.authors.map do |author|
          "#{author.author_first_name} #{author.author_last_name} #{author.author_email} #{author.author_orcid}"
        end.join(' ')
        my_string << abstracts
      end
      self.search_words = my_string
      # this updates without futher callbacks on me
      update_column :search_words, my_string
    end

    def allow_review?
      # do not allow to go into peer review after already published
      return false if pub_state == 'published'
      # do not allow to go into peer review if associated manuscript already accepted or published
      return false if has_accepted_manuscript? || publication_article_doi

      true
    end

    def publication_issn
      latest_resource&.resource_publication&.publication_issn
    end

    # This is the name typed by the user. If there is an associated journal, the
    # journal.title will be the same. But we keep it copied here in case there is no
    # associated journal object.
    # Curators will probably create an associated journal object later.
    def publication_name
      latest_resource&.resource_publication&.publication_name
    end

    def journal
      latest_resource&.journal
    end

    def manuscript_number
      latest_resource&.resource_publication&.manuscript_number
    end

    def latest_manuscript
      latest_resource&.manuscript
    end

    def preprint_issn
      latest_resource&.resource_preprint&.publication_issn
    end

    def preprint_server
      latest_resource&.resource_preprint&.publication_name
    end

    def automatic_ppr?
      return false unless latest_manuscript.present?
      return false if has_accepted_manuscript?
      return false if has_rejected_manuscript?
      return false if publication_article_doi.present?

      true
    end

    # rubocop:disable Naming/PredicateName
    def has_accepted_manuscript?
      return false unless latest_manuscript.present?

      latest_manuscript.accepted?
    end

    def has_rejected_manuscript?
      return false unless latest_manuscript.present?

      latest_manuscript.rejected?
    end
    # rubocop:enable Naming/PredicateName

    def publication_article_doi
      dois = latest_resource.related_identifiers&.select { |id| id.related_identifier_type == 'doi' && id.work_type == 'primary_article' }
      dois&.last&.related_identifier || nil
    end

    def collection?
      # no payment required (no new data uploaded)
      latest_resource&.resource_type&.resource_type == 'collection'
    end

    def submitter_affiliation
      latest_resource&.owner_author&.affiliation
    end

    # overrides reading the pub state so it can set it for caching if it's not set yet
    def pub_state
      return super unless super.blank?

      update(pub_state: calculated_pub_state)
      calculated_pub_state
    end

    def embargoed_until_article_appears?
      return false unless pub_state == 'embargoed'

      found_article_appears = false
      resources.each do |res|
        res.curation_activities.each do |ca|
          next unless ca.status == 'embargoed' && (ca.note&.match('untilArticleAppears') ||
                                          ca.note&.match('1-year blackout period'))

          found_article_appears = true
          break
        end
      end
      found_article_appears
    end

    # returns the publication state based on history
    # finds the latest applicable state from terminal states for each resource/version.
    # We only really care about whether it's some form of published, embargoed or withdrawn
    def calculated_pub_state
      states = resources.map { |res| res.curation_activities&.last&.status }.compact

      return 'withdrawn' if states.last == 'withdrawn'

      states.reverse_each do |state|
        return state if %w[published embargoed].include?(state)
      end

      'unpublished'
    end

    # this is a method that will likely only be used to fill & migrate data to deal with more fine-grained version display
    def fill_resource_view_flags
      my_pub = false
      resources.each do |res|
        res.reload
        ca = res.last_curation_activity
        case ca&.status # nil for no status
        when 'withdrawn'
          res.update_columns(meta_view: false, file_view: false)
        when 'embargoed'
          res.update_columns(meta_view: true, file_view: false)
        when 'published'
          res.update_columns(meta_view: true, file_view: true)
          my_pub = true
        end
      end

      reload

      # don't see if published versions need to be excluded if there are none or if we borked the version history for curators to hide their edits
      return if my_pub == false || borked_file_history?

      # walk through the changes and see if no changes between the file_view (published) ones, if so, reset file_view to false
      # because there is nothing of interest to see in this version of no-file changes between published versions
      unchanged = true
      resources.each do |res|
        unchanged &&= res.files_unchanged?(association: 'data_files')
        if res.file_view == true
          res.update_column(:file_view, false) if unchanged
          unchanged = true
        end
        res.update_column(:file_view, false) unless res.current_file_uploads.present?
      end
    end

    # This tells us if the curators made us orphan all old versions in the resource history in order to make display look pretty.
    # In this case we still may call this and want to show some version of the files because there was never a version remaining
    # in which these files were added to the dataset.
    #
    # I hope once we get the versioning to do what the curators like then we will not have to bork our version data in order to
    # make the display look desireable.  We can also put the old versions back and re-process the info to get corect views for these datasets.
    def borked_file_history?
      # I have been setting resources curators don't like to the negative identifier_id on the resource foreign key to orphan them
      return true if Resource.where(identifier_id: -id).count.positive? || resources.with_file_changes.count.zero?

      false
    end

    # creates a share for this resource if not present
    def create_share
      StashEngine::Share.create(identifier_id: id) if shares.blank?
    end

    # checks if the identifier has a Zenodo software submission or has had any in the past. If we ever have a software
    # submission then we need to keep it up to date each time things change
    # rubocop:disable Naming/PredicateName
    # Nope: I don't think taking the 'has_' off this method is helpful
    def has_zenodo_software?
      SoftwareFile.joins(:resource).where(stash_engine_resources: { identifier_id: id }).count.positive?
    end

    def has_zenodo_supp?
      SuppFile.joins(:resource).where(stash_engine_resources: { identifier_id: id }).count.positive?
    end
    # rubocop:enable Naming/PredicateName

    # gets the resources which are in zenodo and have viewable files for the context, used by the landing page.
    # Only latest version after published is included if include_unpublished is true.
    # It may return an array instead of activerecord relation because it's complicated and UNION isn't really a thing in Rails 4
    def zenodo_software_resources(include_unpublished: false)
      pub = zenodo_published_software_resources
      last_unpub = last_zenodo_resource(copy_type: 'software')

      # just return published if just public flag or if last unpublished doesn't exist
      return pub unless include_unpublished == true || last_unpub.nil?

      # just unpub if none are published
      return [last_unpub] if pub.count < 1

      # just the pub if latest_unpublished is before latest_published, unpub and last pub shouldn't be nil (see above conditions)
      return pub if last_unpub.id < pub.last.id

      (pub.to_a + [last_unpub]).compact
    end

    def zenodo_published_software_resources
      resources.joins(:zenodo_copies).where('stash_engine_zenodo_copies.deposition_id IS NOT NULL')
        .where("stash_engine_zenodo_copies.state = 'finished'")
        .where("stash_engine_zenodo_copies.copy_type = 'software_publish'")
    end

    # this is still an activerecord relation (creating an array of one) so that we can union it with sql
    # copy type is either 'software' or 'software_publish' or (in theory) 'data' (for 3rd copy)
    def last_zenodo_resource(copy_type:)
      resources.joins(:zenodo_copies).where('stash_engine_zenodo_copies.deposition_id IS NOT NULL')
        .where("stash_engine_zenodo_copies.state = 'finished'")
        .where('stash_engine_zenodo_copies.copy_type = ?', copy_type)
        .order(id: :desc).limit(1).first
    end

    # ------------------------------------------------------------
    # Calculated dates

    # returns the date on which this identifier was initially approved for publication
    # (i.e., the date on which it entered the status 'published' or 'embargoed'
    def approval_date
      process_date.approved
    end

    # returns the date on which this identifier was initially referred for author action
    def aar_date
      resources.map(&:curation_activities).flatten.uniq(&:status)
        .select { |ca| ca.status == 'action_required' }.pluck(&:created_at).first
    end

    # returns the date on which this identifier was returned to curators after action_required
    def aar_end_date
      return nil unless aar_date

      changes = resources.map(&:curation_activities).flatten.pluck(:status, :created_at).uniq(&:first)
      prev = changes.index { |c| c.first == 'aar_date' }
      changes[prev + 1]&.last
    end

    def date_available_for_curation
      process_date.submitted
    end

    def curation_completed_date
      process_date.curation_end
    end

    def date_first_curated
      process_date.curation_start
    end

    def date_last_curated
      resources.map(&:process_date).pluck(:curation_start).reject(&:blank?)&.last || nil
    end

    def date_first_published
      publication_date
    end

    def date_last_published
      resources.map(&:publication_date)&.reject(&:blank?)&.last || nil
    end

    # the first time this dataset had metadata exposed to the public
    def datacite_issued_date
      res = resources.with_public_metadata.order(created_at: :asc).first
      return nil unless res.present?

      res.publication_date || res.updated_at
    end

    # the first time this dataset was fully published with files available to download for the public - download true
    def datacite_available_date
      res = resources.files_published.order(created_at: :asc).first
      return nil unless res.present?

      res.publication_date || res.updated_at
    end

    def previous_invoiced_file_size
      last_invoiced_file_size.presence || latest_resource.previous_published_resource&.total_file_size
    end

    # ------------------------------------------------------------
    # Private

    private

    def abstracts
      return '' unless latest_resource.respond_to?(:descriptions)

      ' ' << latest_resource.descriptions.where(description_type: 'abstract').map do |description|
        ActionView::Base.full_sanitizer.sanitize(description.description)
      end.join(' ')
    end

    # it's ok to defer adding this unless someone asks for the counter_stat
    # def build_associations
    #   counter_stat || true
    # end
  end
  # rubocop:enable Metrics/ClassLength
end
