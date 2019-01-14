module StashEngine
  class CurationActivity < ActiveRecord::Base
    belongs_to :stash_identifier, class_name: 'StashEngine::Identifier', foreign_key: 'identifier_id'
    belongs_to :user, class_name: 'StashEngine::User', foreign_key: 'user_id'
    validates :status, inclusion: { in: ['Unsubmitted',
                                         'Submitted',
                                         'Private for Peer Review',
                                         'Curation',
                                         'Author Action Required',
                                         'Embargoed',
                                         'Published',
                                         'Withdrawn',
                                         'Status Unchanged',
                                         'Versioned'],
                                    message: '%{value} is not a valid status' }
    validates :status, presence: true
    after_create :update_identifier_state, :submit_to_datacite
    after_update :update_identifier_state, :submit_to_datacite

    def self.curation_status(my_stash_id)
      curation_activities = CurationActivity.where(stash_identifier: my_stash_id).order(updated_at: :desc)
      curation_activities.each do |activity|
        return activity.status unless activity.status == 'Status Unchanged'
      end
      @curation_status = 'Unsubmitted'
    end

    def as_json(*)
      # {"id":11,"identifier_id":1,"status":"Submitted","user_id":1,"note":"hello hello ssdfs2232343","keywords":null}
      {
        id: id,
        dataset: stash_identifier.to_s,
        status: status,
        action_taken_by: user_name,
        note: note,
        keywords: keywords,
        created_at: created_at,
        updated_at: updated_at
      }
    end

    private

    def update_identifier_state
      return if status == 'Status Unchanged'
      return if stash_identifier.nil?
      return if stash_identifier.identifier_state.nil?
      stash_identifier.identifier_state.update_identifier_state(self)
    end

    def submit_to_datacite
      return unless status_changed? && ( status == 'Published' || status == 'Embargoed' )
      last_merritt_version = stash_identifier&.last_submitted_version_number
      return if last_merritt_version.nil? # don't submit random crap to DataCite unless it's preserved in Merritt
      # only do UPDATEs with DOIs in production because ID updates like to fail in test EZID/DataCite because they delete their identifiers at random
      return if last_merritt_version > 1 && Rails.env != 'production'
      idg = Stash::Doi::IdGen.make_instance(resource: stash_identifier.last_submitted_resource)
      idg.update_identifier_metadata!
    end

    def user_name
      return user.name unless user.nil?
      'System'
    end
  end
end
