require 'resync/client'
require 'active_support/core_ext/range'

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

  class ChangeListIndex
    def each_change(in_range:)
      @change_lists ||= {}
      resources.lazy.each do |r|
        md = r.metadata
        from_time = md.from_time
        until_time = md.until_time || Time.new
        next unless in_range.overlaps?(from_time..until_time)
        @change_lists[r] ||= r.get_and_parse
        @change_lists[r].each_change(in_range: in_range) do |c|
          yield c
        end
      end
    end
  end
end
