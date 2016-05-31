module StashEngine
  class License

    @@licenses_by_uri =
        Hash[ ::LICENSES.map{|k, v| [v['uri'], v.merge({id: k}) ] } ].with_indifferent_access

    def self.by_id(id)
      ::LICENSES[id]
    end

    class << self
      alias_method :find, :by_id
    end

    def self.by_uri(uri)
      @@licenses_by_uri[uri]
    end

  end
end
