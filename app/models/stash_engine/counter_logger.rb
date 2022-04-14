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
      StashEngine.counter_log(line) if required_data?(line: line)
    end

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
        resource.publication_date&.year || Time.new.year
      ]
    end

    # there is a more intense validator at stash/stash_engine/lib/tasks/counter/validate_file.rb, however if something
    # isn't filled in then something is really wrong and this item really isn't released or loggable
    def self.required_data?(line:)
      # these items are required: 0:ip, 4:original_url, 5:identifier_string, 9:title, 10:publisher, 11:publisher_id,
      # 12:authors, 13:publication_date, 16:doi_url, 17:publication_year
      [0, 4, 5, 9, 10, 11, 12, 13, 16, 17].each do |i|
        return false if line[i].blank?
      end
      true
    end

  end
end
