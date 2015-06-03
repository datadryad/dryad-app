require 'resync/client'

module Resync
  class ResourceList
    def each_resource(&block)
      resources.each(&block)
    end
  end

  class ChangeList
    def each_resource(in_range:)
      resources.each do |r|
        next unless in_range.cover?(r.modified_time)
        yield r
      end
    end
  end
end
