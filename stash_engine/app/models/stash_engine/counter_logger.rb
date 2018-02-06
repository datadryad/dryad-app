module StashEngine
  class CounterLogger

    # this logs the following items in TSV format, we may need to encode tabs and/or pipes (for metadata separators) in some cases
    # - IP Address
    # - session ID
    # - GONE type of hit [investigation, investigation:datapaper, request:dataset, request:version, request:file]
    # - URL (this may soon replace  type of hit and we'll have to figure it all out from the URL in processing)
    # - identifier for the dataset
    # - Filename (if applicable) -- we need to encode tabs in the filename if present
    # - size
    # - user-agent
    # - title (resource.title)
    # - publisher (resource.publisher.publisher)
    # - publisher id ????????
    # - creators (r.authors.map{|a| "#{a.author_first_name} #{a.author_last_name}" }.join('%7c'))
    # - publication_date (r.publication_date)
    # - dataset_version (r.stash_version.version)
    # - other ids ?????????
    # - URI (resource.identifier.target)
    # - YOP (year of publication) resource.notional_publication_year

    def self.landing_hit(request:, resource:)
      log_line(request: request, resource: resource) # type: 'investigation'
    end

    def self.landing_datapaper_hit(request:, resource:)
      log_line(request: request, resource: resource) # type: 'investigation:datapaper'
    end

    def self.file_download_hit(request:, file:)
      log_line(request: request, resource: file.resource, filename: file.upload_file_name, size: file.upload_file_size) # type: 'request:file'
    end

    def self.version_download_hit(request:, resource:)
      log_line(request: request, resource: resource, size: resource.size) # 'request:version'
    end

    #
    # these are helper methods
    #

    def self.log_line(request:, resource:, filename: nil, size: nil)
      line = log_array(request: request, resource: resource, filename: filename, size: size)
      StashEngine.counter_log(line)
    end

    def self.log_array(request:, resource:, filename:, size:)
      [
        request.remote_ip, # user's IP Address
        request.session_options[:id], # Session ID
        request.original_url, # the URL the user is requesting
        resource.identifier.to_s, # the identifier for the dataset
        filename, # the filename they requested for download if any
        size, # the size of the download (for a file, if any)
        request.user_agent # the agent sent by the client
      ].concat(log_metadata_array(resource: resource))
    end

    # rubocop:disable Metrics/MethodLength
    def self.log_metadata_array(resource:)
      [
        resource.title,
        resource.try(:publisher).try(:publisher),
        '????', # - publisher id ????????  This may be assigned to us and configured somewhere?
        resource.authors.map { |a| a.author_standard_name.gsub('|', '%7c') }.join('|'), # - creators, escape any pipes in author names
        resource.publication_date,
        resource.try(:stash_version).try(:version),
        '????', # - other ids ?????????  not sure what this would be
        resource.try(:identifier).try(:target), # The landing page url with correct domain and all
        resource.notional_publication_year
      ]
    end
    # rubocop:enable Metrics/MethodLength

  end
end
