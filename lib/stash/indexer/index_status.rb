require 'typesafe_enum'

module Stash
  module Indexer
    class IndexStatus < TypesafeEnum::Base
      [:COMPLETED, :FAILED].each { |s| new s }
    end
  end
end
