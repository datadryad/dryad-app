module StashEngine
  class CounterLogger

    def self.landing_hit(request:, resource:)
      line = self.basic_landing(request: request, resource: resource, type: 'investigation')
      StashEngine.counter_log(line)
    end

    def self.landing_datapaper_hit(request:, resource:)
      line = self.basic_landing(request: request, resource: resource, type: 'investigation:datapaper')
      StashEngine.counter_log(line)
    end

    def self.basic_landing(request:, resource:, type:)
      # IP Address, Session ID, Type of query
      # [investigation, investigation:datapaper, request:dataset, request:version, request-file],
      # filename (if applicable), size, user-agent
      [request.remote_ip, request.session_options[:id], type, resource.identifier.to_s,
       resource.stash_version.version, '', '', request.user_agent]
    end
  end
end