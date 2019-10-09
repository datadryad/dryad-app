require 'httparty'

module StashEngine
  # rubocop:disable Metrics/ClassLength
  class Identifier < ActiveRecord::Base
    has_many :resources, class_name: 'StashEngine::Resource', dependent: :destroy
    has_many :orcid_invitations, class_name: 'StashEngine::OrcidInvitation', dependent: :destroy
    has_one :counter_stat, class_name: 'StashEngine::CounterStat', dependent: :destroy
    has_many :internal_data, class_name: 'StashEngine::InternalDatum', dependent: :destroy
    has_many :external_references, class_name: 'StashEngine::ExternalReference', dependent: :destroy
    # there are places we may have more than one from our old versions
    has_many :shares, class_name: 'StashEngine::Share', dependent: :destroy
    has_one :latest_resource,
            class_name: 'StashEngine::Resource',
            primary_key: 'latest_resource_id',
            foreign_key: 'id'

    after_create :create_share

    # See https://medium.com/rubyinside/active-records-queries-tricks-2546181a98dd for some good tricks
    # returns the identifiers that have resources with that *latest* curation state you specify (for any of the resources)
    # These scopes needs some reworking based on changes to the resource state, leaving them commented out for now.
    # with_visibility, ->(states:, user_id: nil, tenant_id: nil)
    scope :with_visibility, ->(states:, user_id: nil, tenant_id: nil) do
      joins(:resources).merge(Resource.with_visibility(states: states, user_id: user_id, tenant_id: tenant_id)).distinct
    end

    scope :publicly_viewable, -> do
      where(pub_state: %w[published embargoed])
    end

    scope :user_viewable, ->(user: nil) do
      if user.nil?
        publicly_viewable
      elsif user.superuser?
        all
      elsif user.role == 'admin'
        with_visibility(states: %w[published embargoed], tenant_id: user.tenant_id)
      else
        with_visibility(states: %w[published embargoed], user_id: user.id)
      end
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
                                  created_at: Time.new.utc - 1.day, updated_at: Time.new.utc - 1.day)
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
        .joins(:file_uploads)
        .where(stash_engine_file_uploads: { file_state: %w[created deleted] })
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
      return lr if user.id == lr&.user_id || user.superuser? || (user.role == 'admin' && user.tenant_id == lr&.tenant_id)

      latest_resource_with_public_metadata
    end

    def latest_resource_with_public_download
      resources.files_published.by_version_desc.first
    end

    def latest_downloadable_resource(user: nil)
      return latest_resource_with_public_download if user.nil?
      lr = resources.submitted_only.by_version_desc.first
      return lr if user.id == lr&.user_id || user.superuser? || (user.role == 'admin' && user.tenant_id == lr&.tenant_id)
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
      @target = tenant.full_url(StashEngine::Engine.routes.url_helpers.show_path(to_s))
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
    # otherwise covered
    def user_must_pay?
      !journal_will_pay? &&
        !institution_will_pay? &&
        (!submitter_affiliation.present? || !submitter_affiliation.fee_waivered?)
    end

    def publication_data(field_name)
      return nil if publication_issn.nil?
      url = APP_CONFIG.old_dryad_url + '/api/v1/journals/' + publication_issn
      results = HTTParty.get(url,
                             query: { access_token: APP_CONFIG.old_dryad_access_token },
                             headers: { 'Content-Type' => 'application/json' })
      results.parsed_response[field_name]
    end

    def publication_issn
      internal_data.find_by(data_type: 'publicationISSN')&.value
    end

    def manuscript_number
      internal_data.find_by(data_type: 'manuscriptNumber')&.value
    end

    def publication_article_doi
      doi = nil
      resources.each do |res|
        dois = res.related_identifiers&.select { |id| id.related_identifier_type == 'doi' && id.relation_type == 'issupplementto' }
        doi = dois&.first&.related_identifier
        break unless doi.nil?
      end
      doi
    end

    def publication_name
      publication_data('fullName')
    end

    def journal_will_pay?
      plan_type = publication_data('paymentPlanType')
      plan_type == 'SUBSCRIPTION' ||
        plan_type == 'PREPAID' ||
        plan_type == 'DEFERRED'
    end

    def journal_customer_id
      publication_data('stripeCustomerID')
    end

    def journal_notify_contacts
      publication_data('notifyContacts')
    end

    def allow_review?
      publication_data('allowReviewWorkflow') || publication_name.blank?
    end

    def allow_blackout?
      publication_data('allowBlackout').present? && publication_data('allowBlackout')
    end

    def institution_will_pay?
      latest_resource&.tenant&.covers_dpc == true
    end

    def submitter_affiliation
      latest_resource&.authors&.first&.affiliation
    end

    def large_files?
      return if latest_resource.nil?
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
    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
    def fill_resource_view_flags
      my_pub = false
      resources.each do |res|
        ca = res.current_curation_activity
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
        unchanged &&= res.files_unchanged?
        if res.file_view == true
          res.update_column(:file_view, false) if unchanged
          unchanged = true
        end
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength

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
