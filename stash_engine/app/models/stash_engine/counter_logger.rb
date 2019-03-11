module StashEngine
  class CounterLogger

    # this logs the following items in TSV format, we may need to encode tabs and/or pipes (for metadata separators) in some cases
    # see below for what we're logging and in what order

    def self.general_hit(request:, resource: nil, file: nil)
      # request and resource are required for all and identifier, version and much info can be obtained from resource
      filename = nil
      size = nil
      if file
        filename = file.upload_file_name
        size = file.upload_file_size
        resource = file.resource
      end
      log_line(request: request, resource: resource, filename: filename, size: size)
    end

    def self.version_download_hit(request:, resource:)
      log_line(request: request, resource: resource, size: resource.size)
    end

    #
    # these are helper methods
    #

    def self.log_line(request:, resource:, filename: nil, size: nil)
      line = log_array(request: request, resource: resource, filename: filename, size: size)
      StashEngine.counter_log(line)
    end

    # rubocop:disable Metrics/MethodLength
    def self.log_array(request:, resource:, filename:, size:)
      [
        request.remote_ip, # user's IP Address
        nil, # we don't track a session cookie (that expires when a user closes the browser as indicated online as a definition of a session cookie)
        request.session_options[:id], # Session ID (this is a user's session id that references a cookie)
        request.session['user_id'], # this is a user's id number from our database (if they happen to be logged in, rarely the case)
        request.original_url, # the URL the user is requesting
        resource.identifier.to_s, # the identifier for the dataset
        filename, # the filename they requested for download if any
        size, # the size of the download (for a file, if any)
        request.user_agent # the agent sent by the client
      ].concat(log_metadata_array(resource: resource))
    end
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable Metrics/MethodLength
    def self.log_metadata_array(resource:)
      [
        resource.title,
        resource.try(:publisher).try(:publisher),
        resource.tenant.publisher_id, # - publisher id, we're using grid ids
        resource.authors.map { |a| a.author_standard_name.gsub('|', '%7c') }.join('|'), # - creators, escape any pipes in author names
        resource.publication_date,
        resource.try(:stash_version).try(:version),
        '', # - other id
        resource.try(:identifier).try(:target), # The landing page url with correct domain and all
        resource.publication_date
      ]
    end
    # rubocop:enable Metrics/MethodLength

  end
end
