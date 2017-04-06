require 'typesafe_enum'

module Stash
  module Wrapper
    # Controlled vocabulary for {Size#unit}, with the single
    # value {#BYTE}.
    class SizeUnit < TypesafeEnum::Base
      new :BYTE, 'B'
    end
  end
end
