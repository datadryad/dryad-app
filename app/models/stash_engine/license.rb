module StashEngine
  class License
    def self.by_id(id)
      ::LICENSES[id]
    end

    class << self
      alias find by_id
    end

    def self.by_uri(uri)
      licenses_by_uri[uri]
    end

    def self.licenses_by_uri
      @licenses_by_uri ||= ::LICENSES.map { |k, v| [v['uri'], v.merge(id: k)] }.to_h.with_indifferent_access
    end
  end
end
