require 'ruby-enum'

module Stash
  module Wrapper
    class SizeUnit
      include Ruby::Enum
      define :BYTE, 'B'
    end
  end
end
