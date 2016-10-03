module StashEngine
  class Resource < ActiveRecord::Base
    has_many :file_uploads, class_name: 'StashEngine::FileUpload', dependent: :destroy
    has_one :stash_version, class_name: 'StashEngine::Version'
    belongs_to :identifier, class_name: 'StashEngine::Identifier', foreign_key: 'identifier_id'
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
    scope :in_progress, (lambda do
      joins(:current_state).where(stash_engine_resource_states: { resource_state:  :in_progress })
    end)
    scope :submitted, (lambda do
      joins(:current_state).where(stash_engine_resource_states: { resource_state:  [:published, :processing, :error] })
    end)
    scope :by_version_desc, -> { joins(:stash_version).order('stash_engine_versions.version DESC') }
    scope :by_version, -> { joins(:stash_version).order('stash_engine_versions.version ASC') }

    # clean up the uploads with files that no longer exist for this resource
    def clean_uploads
      file_uploads.each do |fu|
        fu.destroy unless File.exist?(fu.temp_file_path)
      end
    end

    # gets the latest files that are not deleted in db, current files for this version
    def current_file_uploads
      subquery = FileUpload.where(resource_id: id).where("file_state <> 'deleted'")
                           .select('max(id) last_id, upload_file_name').group(:upload_file_name)
      FileUpload.joins("INNER JOIN (#{subquery.to_sql}) sub on id = sub.last_id").order(upload_file_name: :asc)
    end

    # the states of the latest files of the same name in the resource (version), included deleted
    def latest_file_states
      subquery = FileUpload.where(resource_id: id)
                           .select('max(id) last_id, upload_file_name').group(:upload_file_name)
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
      update_identifier(doi)
      Rails.logger.debug("Submitting SwordJob for '#{title}' (#{doi})")
      SwordJob.submit_async(
        title: title,
        doi: doi,
        zipfile: zipfile,
        resource_id: id,
        sword_params: current_tenant.sword_params,
        request_host: request_host,
        request_port: request_port
      )
    end

    def update_identifier(doi)
      doi = doi.split(':', 2)[1] if doi.start_with?('doi:')
      if identifier.nil?
        identifier = Identifier.create(identifier: doi, identifier_type: 'DOI')
        self.identifier_id = identifier.id
        save
      else
        self.identifier.update(identifier: doi)
      end
    end

    def update_version(zipfile)
      zip_filename = File.basename(zipfile)
      version = nil
      if stash_version.nil?
        version = StashEngine::Version.new(resource_id: id, zip_filename: zip_filename, version: next_version)
      else
        version = StashEngine::Version.where(resource_id: id, zip_filename: zip_filename).first
        version.version = next_version
      end
      version.save!
    end

    #smartly gives a version number for this resource for either current version if version is already set
    #or what it would be when it is submitted (the versino to be), assuming it's submitted next
    def smart_version
      if stash_version.blank? || stash_version.version.zero?
        next_version
      else
        stash_version.version
      end
    end

    def next_version
      return 1 if identifier.blank?
      last_v = identifier.last_submitted_version
      return 1 if last_v.blank?
      #this looks crazy, but association from resource to version to version field
      last_v.stash_version.version + 1
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

    def current_state=(state_string)
      my_state = ResourceState.create(user_id: user_id, resource_state: state_string, resource_id: id)
      self.current_resource_state_id = my_state.id
      save
    end

    # gets the count of submitted datasets
    def self.submitted_dataset_count
      sql = "SELECT count(*) as my_count FROM\
      (SELECT res.identifier_id\
      FROM stash_engine_resources res\
      JOIN stash_engine_resource_states state\
      ON res.current_resource_state_id = state.id\
      WHERE state.resource_state = 'published'\
      GROUP BY res.identifier_id) as tbl"

      # this query becomes difficult to deal with because of complexity in activerecord and so counting by sql
      # all.joins(:current_state).select(:identifier_id).
      #    where("stash_engine_resource_states.resource_state = 'published'").
      #    group('identifier_id')

      count_by_sql(sql)
    end

    private

    def ensure_resource_usage
      create_resource_usage(downloads: 0, views: 0) if resource_usage.nil?
    end
  end
end
