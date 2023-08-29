require 'httparty'
require 'http'

module StashEngine
  # rubocop:disable Metrics/ClassLength
  class Identifier < ApplicationRecord
    self.table_name = 'stash_engine_identifiers'
    has_many :resources, class_name: 'StashEngine::Resource', dependent: :destroy
    has_many :orcid_invitations, class_name: 'StashEngine::OrcidInvitation', dependent: :destroy
    has_one :counter_stat, class_name: 'StashEngine::CounterStat', dependent: :destroy
    has_many :internal_data, class_name: 'StashEngine::InternalDatum', dependent: :destroy
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

    after_create :create_share

    # This makes the setting of the "preliminary information" and how something was imported explicit.  Default is other.
    # There is only one import per dataset and it overwrites info after getting valid information.
    enum import_info: {
      other: 0,
      manuscript: 1,
      published: 2
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
      ids = publicly_viewable.map(&:id)
      joins(:internal_data)
        .where('stash_engine_identifiers.id IN (?)', ids)
        .where('stash_engine_internal_data.data_type = ? AND stash_engine_internal_data.value IS NOT NULL', 'pubmedID')
        .order('stash_engine_identifiers.identifier')
    end

    scope :cited_by_external_site, ->(site) do
      ids = publicly_viewable.map(&:id)
      joins(:external_references)
        .where('stash_engine_identifiers.id IN (?)', ids)
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

    def resources_with_file_changes
      Resource.distinct.where(identifier_id: id)
        .joins(:data_files)
        .where(stash_engine_generic_files: { file_state: %w[created deleted] })
        .where(stash_engine_generic_files: { type: 'StashEngine::DataFile' })
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
      return lr if lr&.admin_for_this_item?(user: user)

      latest_resource_with_public_metadata
    end

    def latest_resource_with_public_download
      resources.files_published.by_version_desc.first
    end

    def latest_downloadable_resource(user: nil)
      return latest_resource_with_public_download if user.nil?

      lr = resources.submitted_only.by_version_desc.first
      return lr if lr&.admin_for_this_item?(user: user)

      latest_resource_with_public_download
    end

    def may_download?(user: nil)
      !latest_downloadable_resource(user: user).blank?
    end

    def last_submitted_version_number
      (lsv = last_submitted_resource) && lsv.version_number
    end

    # this returns a resource object for the last version in Merritt, caching in instance variable for repeated calls
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

        user = StashEngine::User.find(r.current_editor_id)
        return user if user.curator?
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
    # https://github.com/CDL-Dryad/dryad-product-roadmap/issues/125
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

    # Check if the user must pay for this identifier, or if payment is
    # otherwise covered - but send waivers to stripe
    def user_must_pay?
      !journal&.will_pay? && !institution_will_pay? && !funder_will_pay?
    end

    def journal
      return nil if publication_issn.nil?

      Journal.find_by_issn(publication_issn)
    end

    def record_payment
      # once we have assigned payment to an entity, keep that entity,
      # unless it was a journal that the submission is no longer affiliated with
      # (in general, we don't want to tell a user their payment is covered and then later take it away)
      clear_payment_for_changed_journal
      return if payment_type.present? && payment_type != 'unknown'

      if journal&.will_pay?
        self.payment_type = "journal-#{journal.payment_plan_type}"
        self.payment_id = publication_issn
      elsif institution_will_pay?
        self.payment_id = latest_resource&.tenant&.tenant_id
        self.payment_type = "institution#{'-TIERED' if latest_resource&.tenant&.payment_plan == 'tiered'}"
      elsif submitter_affiliation&.fee_waivered?
        self.payment_type = 'waiver'
        self.waiver_basis = submitter_affiliation.country_name
        self.payment_id = nil
      elsif funder_will_pay?
        contrib = funder_payment_info
        self.payment_type = 'funder'
        self.payment_id = "funder:#{contrib.contributor_name}|award:#{contrib.award_number}"
      else
        self.payment_type = 'unknown'
        self.payment_id = nil
      end
      save
    end

    def allow_review?
      # do not allow to go into peer review after already published
      return false if pub_state == 'published'
      # do not allow to go into peer review if associated manuscript already accepted or published
      return false if has_accepted_manuscript? || publication_article_doi
      return true if journal.blank?
      return true if last_submitted_resource&.current_curation_status == 'peer_review'

      journal.allow_review_workflow?
    end

    def allow_blackout?
      return false if journal.blank?

      journal.allow_blackout?
    end

    def publication_issn
      internal_data.find_by(data_type: 'publicationISSN')&.value&.strip
    end

    # This is the name typed by the user. If there is an associated journal, the
    # journal.title will be the same. But we keep it copied here in case there is no
    # associated journal object.
    # Curators will probably create an associated journal object later.
    def publication_name
      internal_data.find_by(data_type: 'publicationName')&.value&.strip
    end

    def manuscript_number
      internal_data.find_by(data_type: 'manuscriptNumber')&.value&.strip
    end

    # rubocop:disable Naming/PredicateName
    def has_accepted_manuscript?
      manu = StashEngine::Manuscript.where(manuscript_number: manuscript_number).last
      return false unless manu

      manu.accepted?
    end
    # rubocop:enable Naming/PredicateName

    def publication_article_doi
      doi = nil
      resources.each do |res|
        dois = res.related_identifiers&.select { |id| id.related_identifier_type == 'doi' && id.work_type == 'primary_article' }
        doi = dois&.last&.related_identifier
        break unless doi.nil?
      end
      doi
    end

    def institution_will_pay?
      latest_resource&.tenant&.covers_dpc == true
    end

    def funder_will_pay?
      return false if latest_resource.nil?

      latest_resource.contributors.each { |contrib| return true if contrib.payment_exempted? }

      false
    end

    def funder_payment_info
      return nil unless funder_will_pay?

      latest_resource.contributors.each { |contrib| return contrib if contrib.payment_exempted? }
    end

    def submitter_affiliation
      latest_resource&.owner_author&.affiliation
    end

    def large_files?
      return false if latest_resource.nil?

      latest_resource.size > APP_CONFIG.payments['large_file_size']
    end

    # overrides reading the pub state so it can set it for caching if it's not set yet
    def pub_state
      my_state = read_attribute(:pub_state)
      return my_state unless my_state.nil?

      my_state = calculated_pub_state
      update_column(:pub_state, my_state) # avoid any callbacks and validations which will only stir up trouble
      my_state
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
      return true if Resource.where(identifier_id: -id).count.positive? || resources_with_file_changes.count.zero?

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

    # Info about dataset object from Merritt. See spec/fixtures/merritt_local_id_search_response.json for an example.
    # Currently used for checking if things have gone into Merritt yet, but may be used for other purposes in the future.
    def merritt_object_info
      repo = APP_CONFIG[:repository]
      collection = repo.endpoint.match(%r{[^/]+$}).to_s
      enc_doi = ERB::Util.url_encode(to_s)
      resp = HTTP.basic_auth(user: repo.username, pass: repo.password)
        .headers(accept: 'application/json')
        .get("#{repo.domain}/api/#{collection}/local_id_search?terms=#{enc_doi}")
      return resp.parse if resp.headers['content-type'].start_with?('application/json')

      {}
    rescue HTTP::Error, JSON::ParserError
      {}
    end

    # ------------------------------------------------------------
    # Calculated dates

    # returns the date on which this identifier was initially approved for publication
    # (i.e., the date on which it entered the status 'published' or 'embargoed'
    def approval_date
      return nil unless %w[published embargoed].include?(pub_state)

      found_approval_date = nil
      resources.reverse_each do |res|
        res.curation_activities.each do |ca|
          next unless %w[published embargoed].include?(ca.status)

          found_approval_date = ca.created_at
          break
        end
      end
      found_approval_date
    end

    # returns the date on which this identifier was initially referred for author action
    def aar_date
      resources.map(&:curation_activities).flatten.each do |ca|
        return ca.created_at if ca.action_required?
      end
      nil
    end

    # returns the date on which this identifier was returned to curators after action_required
    def aar_end_date
      found_aar = false
      resources.map(&:curation_activities).flatten.each do |ca|
        found_aar = true if ca.action_required?
        return ca.created_at if found_aar && !ca.action_required?
      end
      nil
    end

    def date_available_for_curation
      resources.map(&:curation_activities).flatten.each do |ca|
        return ca.created_at if ca.submitted?
      end
      nil
    end

    def curation_completed_date
      return nil unless %w[action_required published embargoed withdrawn].include?(pub_state)

      found_cc_date = nil
      resources.map(&:curation_activities).flatten.each do |ca|
        next unless %w[action_required published embargoed withdrawn].include?(ca.status)

        found_cc_date = ca.created_at
        break
      end
      found_cc_date
    end

    def date_first_curated
      resources.map(&:curation_activities).flatten.each do |ca|
        return ca.created_at if ca.curation?
      end
      nil
    end

    def date_last_curated
      resources.map(&:curation_activities).flatten.reverse.each do |ca|
        return ca.created_at if ca.curation?
      end
      nil
    end

    def date_first_published
      resources.map(&:curation_activities).flatten.each do |ca|
        return ca.created_at if ca.published? || ca.embargoed?
      end
      nil
    end

    def date_last_published
      resources.map(&:curation_activities).flatten.reverse.each do |ca|
        return ca.created_at if ca.published? || ca.embargoed?
      end
      nil
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

    # ------------------------------------------------------------
    # Private

    private

    def clear_payment_for_changed_journal
      return unless payment_type.present?
      return unless payment_type.include?('journal')
      return if payment_id == journal&.single_issn

      self.payment_type = nil
      self.payment_id = nil
      save
    end

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
