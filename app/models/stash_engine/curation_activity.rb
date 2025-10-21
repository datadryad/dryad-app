# == Schema Information
#
# Table name: stash_engine_curation_activities
#
#  id            :integer          not null, primary key
#  deleted_at    :datetime
#  keywords      :string(191)
#  note          :text(65535)
#  status        :string(191)      default("in_progress")
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  identifier_id :integer
#  resource_id   :integer
#  user_id       :integer
#
# Indexes
#
#  index_stash_engine_curation_activities_on_deleted_at          (deleted_at)
#  index_stash_engine_curation_activities_on_identifier_id       (identifier_id)
#  index_stash_engine_curation_activities_on_resource_id_and_id  (resource_id,id)
#
require 'stash/doi/datacite_gen'
require 'stash/payments/invoicer'
module StashEngine

  class CurationActivity < ApplicationRecord
    self.table_name = 'stash_engine_curation_activities'
    acts_as_paranoid

    # Associations
    # ------------------------------------------
    belongs_to :resource, class_name: 'StashEngine::Resource', foreign_key: 'resource_id'
    belongs_to :identifier, class_name: 'StashEngine::Identifier', foreign_key: 'identifier_id'
    belongs_to :user, class_name: 'StashEngine::User', foreign_key: 'user_id'

    # same as above, but includes deleted records
    belongs_to :resource_with_deleted, -> { with_deleted }, class_name: 'StashEngine::Resource', foreign_key: 'resource_id'
    belongs_to :identifier_with_deleted, -> { with_deleted }, class_name: 'StashEngine::Identifier', foreign_key: 'identifier_id'

    # Explanation of statuses
    #  :in_progress <-- When the resource's current resource_state != 'submitted'
    #                  This is the initial default value set on initialize
    #
    #  :submitted   <-- When the resource's current resource_state == 'submitted'
    #                  This is set by a callback on ResourceState.save
    #
    #  :curation, :action_required, :published, :embargoed and :withdrawn are all manually
    #  set by the Curator on the Admin page.
    #
    #  :published   <-- Is set by the Curator via the UI OR automatically set when the
    #                   Resource's publication_date has reached maturity
    #
    enum_vals = %w[
      in_progress
      processing
      submitted
      peer_review
      curation
      action_required
      withdrawn
      embargoed
      to_be_published
      published
    ]
    enum :status, enum_vals.index_by(&:to_sym), default: 'in_progress', validate: true

    # I'm making this more explicit because the view helper that did this was confusing and complex.
    # We also need to enforce states outside of the select list in the view.
    #
    # Note that setting the next state to the same as the current state is just to add a note and doesn't actually
    # change state in practice.  The UI may choose not to display the same state in the list, but it is allowed.
    CURATOR_ALLOWED_STATES = {
      in_progress: %w[in_progress],
      processing: %w[in_progress processing],
      submitted: %w[submitted curation withdrawn peer_review],
      peer_review: %w[peer_review submitted curation withdrawn],
      curation: (enum_vals - %w[in_progress submitted to_be_published]),
      action_required: (enum_vals - %w[in_progress submitted to_be_published]),
      withdrawn: %w[withdrawn curation],
      embargoed: %w[embargoed curation withdrawn published],
      to_be_published: %w[embargoed curation withdrawn to_be_published published],
      published: (enum_vals - %w[in_progress submitted to_be_published])
    }.with_indifferent_access.freeze

    # Validations
    # ------------------------------------------
    validates :resource, presence: true

    # Scopes
    # ------------------------------------------
    scope :latest, ->(resource:) {
      where(resource_id: resource.id).order(updated_at: :desc, id: :desc).first
    }

    # Callbacks
    # ------------------------------------------
    before_validation :set_resource

    # Class methods
    # ------------------------------------------
    # Translates the enum value to a human readable status
    def self.readable_status(status)
      status = status.first if status.is_a?(Array)
      return '' unless status.present?

      case status
      when 'error'
        'Upload error'
      when 'peer_review'
        'Private for peer review'
      when 'action_required'
        'Action required'
      else
        status.humanize
      end
    end

    def self.allowed_states(current_state, current_user)
      statuses = CURATOR_ALLOWED_STATES[current_state].dup
      statuses << 'withdrawn' if current_user.min_manager? # data managers can withdraw a datasets from any status
      statuses.uniq
    end

    # Instance methods
    # ------------------------------------------

    def set_resource
      self.resource = StashEngine::Resource.find_by(id: resource_id) if resource.blank?
    end

    # Not sure why this uses splat? http://andrewberls.com/blog/post/naked-asterisk-parameters-in-ruby
    # maybe this calls super somehow and is useful for some reason, though I don't see it documented in the
    # ActiveModel::Serializers::JSON .
    def as_json(*)
      # {"id":11,"identifier_id":1,"status":"Submitted","user_id":1,"note":"hello hello ssdfs2232343","keywords":null}
      {
        id: id,
        dataset: resource.identifier.to_s,
        status: readable_status,
        action_taken_by: user_name,
        note: note,
        keywords: keywords,
        created_at: created_at,
        updated_at: updated_at
      }
    end

    # Local instance method that sends the current status to the class method
    # for translation
    def readable_status
      CurationActivity.readable_status(status)
    end

    # Helper methods
    # ------------------------------------------

    def previous_status
      resource&.curation_activities&.where('id < ?', id)&.order(updated_at: :desc, id: :desc)&.last&.status
    end

    def user_name
      return user.name unless user.nil?

      'System'
    end

    def delete_calculation_date_value
      existing_date = resource.identifier.process_date[:delete_calculation_date]
      return created_at if existing_date.blank?

      [created_at, existing_date].max
    end

    def curation_status_changed?
      return true if previous_status.blank?

      status != previous_status
    end

    def first_time_in_status?
      return false unless curation_status_changed?
      return true unless resource

      resource.curation_activities.where('id < ?', id).where(status: status).empty?
    end

    def previously_published?
      return false unless resource

      # ignoring the current CA, is there an embargoed or published status at any point for this identifier?
      resource.identifier.resources.map(&:curation_activities).flatten.reject { |ca| ca.id == id }
        .map(&:status).intersect?(%w[published embargoed]) || false
    end

    def can_update_pub_state?(status)
      %w[published embargoed peer_review withdrawn].include?(status)
    end

    def ready_for_payment?
      return false unless resource
      return false unless resource.identifier

      resource.identifier.reload
      return false unless resource.identifier.old_payment_system
      return false unless first_time_in_status?

      APP_CONFIG&.payments&.service == 'stripe' &&
        (resource.identifier.payment_type.nil? || %w[unknown waiver stripe].include?(resource.identifier.payment_type)) &&
        %w[published to_be_published embargoed].include?(status)
    end

    def should_update_doi?
      last_repo_version = resource&.identifier&.last_submitted_version_number
      # don't submit random crap to DataCite unless it's preserved
      logger.info("SKIP_DOI_UPDATE due to 'last_repo_version' #{last_repo_version}") and return false if last_repo_version.nil?

      # only do UPDATES with DOIs in production because ID updates like to fail in test DataCite because they delete their identifiers at random
      if last_repo_version > 1 && APP_CONFIG[:identifier_service][:prefix] == '10.7959'
        logger.info("SKIP_DOI_UPDATE due to 'last_repo_version' #{last_repo_version} && #{APP_CONFIG[:identifier_service][:prefix]}") and return false
      end

      true
    end
  end
end
