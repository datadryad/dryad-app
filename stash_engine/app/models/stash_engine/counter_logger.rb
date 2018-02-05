module StashEngine
  class CounterLogger

    # this logs the following items in TSV format, we may need to encode tabs and/or pipes (for metadata separators) in some cases
    # - IP Address
    # - session ID
    # - type of hit [investigation, investigation:datapaper, request:dataset, request:version, request:file]
    # - URL (this may soon replace  type of hit and we'll have to figure it all out from the URL in processing)
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
      basic_non_file(request: request, resource: resource, type: 'investigation')
    end

    def self.landing_datapaper_hit(request:, resource:)
      basic_non_file(request: request, resource: resource, type: 'investigation:datapaper')
    end

    def self.file_download_hit(request:, file:)
      basic_file_dl(request: request, file: file, type: 'request:file')
    end

    def self.version_download_hit(request:, resource:)
      size = resource.size.to_s
      basic_non_file(request: request, resource: resource, type: 'request:version', size: size)
    end

    # these are helper methods for the main ones

    def self.basic_non_file(request:, resource:, type:, size: '')
      # IP Address, Session ID, Type of query
      # [investigation, investigation:datapaper, request:dataset, request:version, request:file],
      # filename (if applicable), size, user-agent
      line = [request.remote_ip, request.session_options[:id], type, resource.identifier.to_s,
              resource.stash_version.version, '', size, request.user_agent]
      StashEngine.counter_log(line)
    end

    def self.basic_file_dl(request:, file:, type:)
      resource = file.resource
      line = [request.remote_ip, request.session_options[:id], type, resource.identifier.to_s,
              resource.stash_version.version, file.upload_file_name, file.upload_file_size, request.user_agent]
      StashEngine.counter_log(line)
    end
  end
end
