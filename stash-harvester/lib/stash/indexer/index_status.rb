require 'typesafe_enum'

# TODO: move up and rename to JobStatus or something
module Stash
  module Indexer
    class IndexStatus < TypesafeEnum::Base
      %i[COMPLETED FAILED].each { |s| new s }
    end
  end
end
