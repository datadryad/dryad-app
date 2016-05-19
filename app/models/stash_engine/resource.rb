require 'stash/sword'

module StashEngine
  class Resource < ActiveRecord::Base
    has_many :file_uploads, class_name: 'StashEngine::FileUpload'
    has_one :version, class_name: 'StashEngine::Version'
    belongs_to :identifier, :class_name => 'StashEngine::Identifier', foreign_key: 'identifier_id'
    has_one :resource_usage, class_name: 'StashEngine::ResourceUsage'
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
    scope :in_progress, -> { joins(:current_state).where(stash_engine_resource_states: {resource_state:  :in_progress}) }
    scope :submitted, -> { joins(:current_state).where(stash_engine_resource_states: {resource_state:  :submitted}) }
    scope :last_version, -> { joins(:version).order('stash_engine_versions.version DESC').first }

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
      client = Stash::Sword::Client.new(username: repo.username, password: repo.password)
      response = client.post_create(collection_uri: repo.endpoint, zipfile: zipfile, slug: doi)
      self.download_uri = extract_download_url(response, current_tenant)
      self.save # save my download URL for this resource
      update_identifier(doi)
      update_version(zipfile)
    end

    def update_identifier(doi)
      doi = doi.split(':', 2)[1] if doi.start_with?('doi:')
      if self.identifier.nil?
        identifier = Identifier.create(identifier: doi, identifier_type: 'DOI')
        self.identifier_id = identifier.id
        save
      else
        self.identifier.update(identifier: doi)
      end
    end

    def update_version(zipfile)
      zip_filename = File.basename(zipfile)
      if self.version.nil?
        version = Version.new(resource_id: id, zip_filename: zip_filename, version: next_version)
        version.save!
      else
        version = Version.where(resource_id: id, zip_filename: zip_filename).first
        version.version = next_version
        version.save!
      end
    end

    #smartly gives a version number for this resource for either current version if version is already set
    #or what it would be when it is submitted (the versino to be), assuming it's submitted next
    def smart_version
      if self.version.blank? || self.version.version == 0
        next_version
      else
        self.version.version
      end
    end

    def next_version
      if self.identifier.blank?
        return 1
      else
        last_version = self.identifier.last_submitted_version
        if last_version.blank?
          1
        else
          #this looks crazy, but association from resource to version to version field
          last_version.version.version + 1
        end
      end
    end

    # Extracting the dl URL is kludgy because it's not being returned directly
    def extract_download_url(xml_response, current_tenant)
      doc = Nokogiri::XML(xml_response)
      doc.remove_namespaces!
      icky_id = doc.xpath('/entry/id').first.text
      id = icky_id[/ark:.+$/]

      # get endpoint domain
      #uri = URI.parse(current_tenant.repository.endpoint)
      mrt_host = current_tenant.repository.domain

      "http://#{mrt_host}/d/#{CGI.escape(id)}"
    end

    def increment_downloads
      ensure_resource_usage
      resource_usage.increment(:downloads).save
    end

    def increment_views
      ensure_resource_usage
      resource_usage.increment(:views).save
    end

    private
    def ensure_resource_usage
      if resource_usage.nil?
        create_resource_usage(downloads: 0, views: 0)
      end
    end
  end
end
