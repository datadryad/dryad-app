module StashEngine
  class Resource < ActiveRecord::Base
    has_many :file_uploads, class_name: 'StashEngine::FileUpload'
    has_and_belongs_to_many :subjects, class_name: 'StashDatacite::Subject'
    belongs_to :user
    has_one :current_state,
            class_name: 'StashEngine::ResourceState',
            primary_key: 'current_resource_state_id',
            foreign_key: 'id'
    #StashEngine.belong_to_resource.each do |i|
    #  has_many i.downcase, class_name: "#{}::"
    #end

    #resource_states
    scope :in_progress, -> { joins(:current_state).where('resource_states.resource_state =?', :in_progress) }
    scope :submitted, -> { joins(:current_state).where('resource_states.resource_state =?', :submitted) }

    # clean up the uploads with files that no longer exist for this resource
    def clean_uploads
      file_uploads.each do |fu|
        fu.destroy unless File.exist?(fu.temp_file_path)
      end
    end

    def display_state
      return '' if self.current_state.nil?
      self.current_state.display_state
    end

    def current_resource_state
      unless self.current_resource_state_id.nil? || self.current_resource_state_id.blank?
        id  = self.current_resource_state_id
        state = ResourceState.find(id).resource_state
        return state
      else
        ResourceState.create!(resource_id: self.id, user_id: self.user_id, resource_state: :in_progress)
      end
    end
  end
end
