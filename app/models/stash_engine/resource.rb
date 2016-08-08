module StashEngine
  class Resource < ActiveRecord::Base
    has_many :file_uploads, class_name: 'StashEngine::FileUpload'
    has_one :version, class_name: 'StashEngine::Version'
    belongs_to :identifier, :class_name => 'StashEngine::Identifier', foreign_key: 'identifier_id'
    has_one :resource_usage, class_name: 'StashEngine::ResourceUsage'
    # # rubocop:disable all
    # has_and_belongs_to_many :subjects, class_name: 'StashDatacite::Subject'
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
    scope :submitted, -> { joins(:current_state).where(stash_engine_resource_states: {resource_state:  [:published, :processing, :error]}) }
    scope :by_version_desc, -> { joins(:version).order('stash_engine_versions.version DESC') }
    scope :by_version, -> { joins(:version).order('stash_engine_versions.version ASC') }

    # clean up the uploads with files that no longer exist for this resource
    def clean_uploads
      file_uploads.each do |fu|
        fu.destroy unless File.exist?(fu.temp_file_path)
      end
    end

    def current_file_uploads
      # gets the latest files that are not deleted in db
      subquery = FileUpload.where(resource_id: id).where("file_state <> 'deleted'").
          select("max(id) last_id, upload_file_name").group(:upload_file_name)
      FileUpload.joins("INNER JOIN (#{subquery.to_sql}) sub on id = sub.last_id").order(upload_file_name: :asc)
    end

    def latest_file_states
      subquery = FileUpload.where(resource_id: id).
          select("max(id) last_id, upload_file_name").group(:upload_file_name)
      FileUpload.joins("INNER JOIN (#{subquery.to_sql}) sub on id = sub.last_id").order(upload_file_name: :asc)
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

    def submission_to_repository(current_tenant, zipfile, title, doi, request_host, request_port)
      self.update_identifier(doi)
      Rails::logger.debug("Submitting SwordJob for '#{title}' (#{doi})")
      SwordJob.submit_async(
          title: title,
          doi: doi,
          zipfile: zipfile,
          resource_id: self.id,
          sword_params: current_tenant.sword_params,
          request_host: request_host,
          request_port: request_port
      )
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
        last_v = self.identifier.last_submitted_version
        if last_v.blank?
          1
        else
          #this looks crazy, but association from resource to version to version field
          last_v.version.version + 1
        end
      end
    end

    # this bit of code may be useful to run in a console to update old items
    # res = StashEngine::Resource.where('download_uri IS NOT NULL')
    # res.each do |r|
    #   if r.update_uri.nil? && r.identifier
    #     id = r.identifier
    #     str_id = CGI.escape("#{id.identifier_type.downcase}:#{id.identifier}")
    #     r.update_uri = "http://sword-aws-dev.cdlib.org:39001/mrtsword/edit/dash_ucb/#{str_id}"
    #     r.save
    #   end
    # end

    #:download_uri and :update_uri returned in hash
    # def extract_urls(xml_response)
    #   doc = Nokogiri::XML(xml_response)
    #   doc.remove_namespaces!
    #   { download_uri: doc.xpath("/entry/link[@rel='edit-media']").first.attribute('href').to_s,
    #     update_uri: doc.xpath("/entry/link[@rel='edit']").first.attribute('href').to_s }
    # end

    def increment_downloads
      ensure_resource_usage
      resource_usage.increment(:downloads).save
    end

    def increment_views
      ensure_resource_usage
      resource_usage.increment(:views).save
    end

    def set_state(state_string)
      state = ResourceState.create(user_id: user_id, resource_state: state_string, resource_id: id)
      current_resource_state_id = state.id
      save
    end

    private
    def ensure_resource_usage
      if resource_usage.nil?
        create_resource_usage(downloads: 0, views: 0)
      end
    end
  end
end
