require 'digest'

module Stash
  module ZenodoSoftware
    class Digests

      DIGEST_INITIALIZERS = {
        'md5' => -> { Digest::MD5.new },
        'sha-1' => -> { Digest::SHA1.new },
        'sha-256' => -> { Digest::SHA256.new },
        'sha-384' => -> { Digest::SHA384.new },
        'sha-512' => -> { Digest::SHA512.new }
      }.with_indifferent_access.freeze

      # set up new blank digests for each type
      def initialize(digest_types: [])
        @digest_accumulator = {}
        digest_types.each do |a_type|
          raise "Digest Type #{a_type} is unknown" unless DIGEST_INITIALIZERS.keys.include?(a_type)

          @digest_accumulator[a_type] = DIGEST_INITIALIZERS[a_type].call
        end
      end

      # called by streamer to accumulate digest info by chunk
      def accumulate_digests(chunk:)
        @digest_accumulator.each_pair do |_k, v|
          v.update(chunk)
        end
      end

      # returns hash with key of digest-type and value of hex digest
      def hex_digests
        # output hexdigests
        digests = {}
        @digest_accumulator.each_pair do |k, v|
          digests[k] = v.hexdigest
        end
        digests
      end
    end
  end
end
