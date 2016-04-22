require 'stash/sword'

module StashEngine
  class Resource < ActiveRecord::Base
    has_many :file_uploads, class_name: 'StashEngine::FileUpload'
    # rubocop:disable all
    has_and_belongs_to_many :subjects, class_name: 'StashDatacite::Subject'
    # rubocop:enable all
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


    def current_resource_state
      if current_resource_state_id.blank?
        ResourceState.create!(resource_id: id, user_id: user_id, resource_state: :in_progress)
      else
        id = current_resource_state_id
        state = ResourceState.find(id).resource_state
        return state
      end
    end

    def submission_to_repository(current_tenant, zipfile, doi)
      repo = current_tenant.repository
      collection_uri = "https://uc3-mrtsword-dev.cdlib.org:39001/mrtsword/collection/#{repo.collection}"
      client = Stash::Sword::Client.new(username: repo.username, password: repo.password)
      client.post_create(collection_uri: collection_uri, zipfile: zipfile, slug: doi)
    end
  end
end
