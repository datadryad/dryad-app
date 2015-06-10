require 'resync/client'
require 'active_support/core_ext/range'

# TODO: prepend named extension modules
# TODO: make these more idiomatic -- named lazy objects?
module Resync
  class ResourceList
    def each_resource(&block)
      resources.each(&block)
    end
  end

  class ChangeList
    def each_change(in_range:, &block)
      changes(in_range: in_range).each(&block)
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
    def each_change(in_range:, &block)
      @change_lists ||= {}
      change_lists(in_range: in_range).each do |cl|
        @change_lists[cl] ||= cl.get_and_parse
        @change_lists[cl].each_change(in_range: in_range, &block)
      end
    end
  end
end
