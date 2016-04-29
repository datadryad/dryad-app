require 'stash/sword'

module StashEngine
  class Resource < ActiveRecord::Base
    has_many :file_uploads, class_name: 'StashEngine::FileUpload'
    has_one :version, class_name: 'StashEngine::Version'
    has_one :identifier, class_name: 'StashEngine::Identifier'
    # rubocop:disable all
    has_and_belongs_to_many :subjects, class_name: 'StashDatacite::Subject'
    # rubocop:enable all
    belongs_to :user, class_name: 'StashEngine::User'
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
      collection_uri = "http://uc3-mrtsword-dev.cdlib.org:39001/mrtsword/collection/#{repo.collection}"
      client = Stash::Sword::Client.new(username: repo.username, password: repo.password)
      client.post_create(collection_uri: collection_uri, zipfile: zipfile, slug: doi)
      update_identifier(doi)
      update_version(zipfile)
    end

    def update_identifier(doi)
      unless self.identifier.nil?
        identifier = Identifier.where(resource_id: id).first
        identifier.update(identifier: doi)
     else
        identifier = Identifier.create(resource_id: id, identifier: doi, identifier_type: 'DOI')
      end
    end

    def update_version(zipfile)
      zip_filename = File.basename(zipfile)
      unless self.version.nil?
        version = Version.where(resource_id: id, zip_filename: zip_filename).first
        version.increment(:version)
        version.save!
      else
        version = Version.new(resource_id: id, zip_filename: zip_filename)
        version.increment(:version)
        version.save!
      end
    end

  end
end
