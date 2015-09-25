require 'ruby-enum'

module Stash
  module Wrapper
    class EmbargoType
      include Ruby::Enum

      define :NONE, 'none'
      define :DOWNLOAD, 'download'
      define :DESCRIPTION, 'description'
    end
  end
end
