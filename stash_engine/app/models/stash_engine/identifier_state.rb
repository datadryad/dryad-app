module StashEngine
  class IdentifierState < ActiveRecord::Base
    belongs_to :identifier, class_name: 'StashEngine::Identifier', foreign_key: 'identifier_id'
    belongs_to :curation_activity, class_name: 'StashEngine::CurationActivity', foreign_key: 'curation_activity_id'

    def self.create_identifier_state(id, c_a)
      id_state = IdentifierState.new(identifier: id, curation_activity: c_a, current_curation_status: c_a.status)
      id_state.save!
      id_state
    end

    def update_identifier_state(c_a)
      return if c_a.status.equal?('Status Unchanged')
      return if !curation_activity.nil? && c_a.created_at < curation_activity.created_at
      update(curation_activity: c_a, current_curation_status: c_a.status)
    end
  end
end
