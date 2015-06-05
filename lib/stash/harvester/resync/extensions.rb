require 'resync/client'

# TODO: prepend named extension modules
# TODO: make these more idiomatic -- named lazy objects?
module Resync
  class ResourceList
    def each_resource(&block)
      resources.lazy.each(&block)
    end
  end

  class ChangeList
    def each_change(in_range:)
      resources.lazy.each do |r|
        next unless in_range.cover?(r.modified_time)
        yield r
      end
    end
  end

  class ResourceListIndex
    def each_resource(&block)
      @resource_lists ||= {}
      resources.lazy.each do |r|
        @resource_lists[r] ||= r.get_and_parse
        @resource_lists[r].each_resource(&block)
      end
    end
  end
end
