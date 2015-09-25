require 'ruby-enum'

module Stash
  module Wrapper
    # Controlled vocabulary for {Size#unit}, with the single
    # value {#BYTE}.
    class SizeUnit
      include Ruby::Enum
      define :BYTE, 'B'
    end
  end
end
