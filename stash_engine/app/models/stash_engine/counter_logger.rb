module StashEngine
  class CounterLogger

    def self.landing_hit(request:, resource:)
      basic_landing(request: request, resource: resource, type: 'investigation')
    end

    def self.landing_datapaper_hit(request:, resource:)
      basic_landing(request: request, resource: resource, type: 'investigation:datapaper')
    end

    def self.file_download_hit(request:, file:)
      basic_file_dl(request: request, file: file, type: 'request:file')
    end

    # these are helper methods for the main ones

    def self.basic_landing(request:, resource:, type:)
      # IP Address, Session ID, Type of query
      # [investigation, investigation:datapaper, request:dataset, request:version, request:file],
      # filename (if applicable), size, user-agent
      line = [request.remote_ip, request.session_options[:id], type, resource.identifier.to_s,
              resource.stash_version.version, '', '', request.user_agent]
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
