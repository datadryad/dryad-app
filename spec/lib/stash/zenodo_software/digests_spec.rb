require 'stash/zenodo_software/digests'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module ZenodoSoftware
    RSpec.describe Digests do

      describe 'initialize' do
        it 'raises an error if a bad digest type is given' do
          expect { Digests.new(digest_types: %w[catfood md5]) }.to raise_error(RuntimeError)
        end
      end

      describe 'accumulate_digest' do
        it 'takes a chunk and adds to digest calculations for the target digest types' do
          dig = Digests.new(digest_types: %w[md5 sha-1 sha-256 sha-384 sha-512])
          dig.accumulate_digests(chunk: 'abcde')

          d = dig.instance_variable_get(:@digest_accumulator)
          expect(d['md5'].hexdigest).to eq(Digest::MD5.hexdigest('abcde'))
          expect(d['sha-1'].hexdigest).to eq(Digest::SHA1.hexdigest('abcde'))
          expect(d['sha-256'].hexdigest).to eq(Digest::SHA256.hexdigest('abcde'))
          expect(d['sha-384'].hexdigest).to eq(Digest::SHA384.hexdigest('abcde'))
          expect(d['sha-512'].hexdigest).to eq(Digest::SHA512.hexdigest('abcde'))
        end
      end

      describe 'hex_digests' do
        it 'returns final hex digests for all the types specified' do
          dig = Digests.new(digest_types: %w[md5 sha-1 sha-256 sha-384 sha-512])
          dig.accumulate_digests(chunk: 'abcde')
          dig.accumulate_digests(chunk: 'fghij')
          dig.accumulate_digests(chunk: 'klmno')
          dig.accumulate_digests(chunk: 'pqrst')
          dig.accumulate_digests(chunk: 'uvwxyz')
          output = dig.hex_digests
          str = 'abcdefghijklmnopqrstuvwxyz'

          expect(output['md5']).to eq(Digest::MD5.hexdigest(str))
          expect(output['sha-1']).to eq(Digest::SHA1.hexdigest(str))
          expect(output['sha-256']).to eq(Digest::SHA256.hexdigest(str))
          expect(output['sha-384']).to eq(Digest::SHA384.hexdigest(str))
          expect(output['sha-512']).to eq(Digest::SHA512.hexdigest(str))
        end
      end

    end
  end
end
