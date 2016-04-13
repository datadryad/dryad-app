module StashEngine
  class ResourceState < ActiveRecord::Base
    belongs_to :user
    belongs_to :resource

    enum resource_state: { in_progress: 'in_progress', submitted: 'submitted', revised: 'revised', deleted: 'deleted' }
    validates :resource_state, presence: true

    after_create :update_current_resource_state

    # def display_state
    #   return '' if self.resource_state.nil?
    #   resource_states[self.resource_state]
    # end

    private

    def update_current_resource_state
      #update the current resource pointer in the resource
      r = resource
      r.current_resource_state_id = id
      r.save!
    end
  end
end
