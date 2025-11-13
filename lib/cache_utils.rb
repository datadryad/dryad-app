class CacheUtils
  include Singleton

  class << self
    def clear_ror_related_cache
      Rails.cache.redis.with do |conn|
        conn.scan_each(match: "related_ror_ids_for_*") do |key|
          conn.del(key)
        end
        conn.scan_each(match: "related_ror_names_for_*") do |key|
          conn.del(key)
        end
      end
    end
  end
end
