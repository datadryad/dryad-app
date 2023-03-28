require_relative '../../../../lib/stash/compressed/tar_gz'
require 'byebug'

require 'spec/support/helpers/http_range_helper'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module Compressed
    RSpec.describe :tar_gz do

      include HttpRangeHelper

      # basic test, more in zip_info_spec.rb and this is shared mixin with tar_gz
      describe '#size' do
        it 'returns the size of the zip file' do
          stub_range_request(url: 'https://example.com/sample.tar.gz', r_start: 0, r_end: 0, body: '', file_size: 389)

          zi = Stash::Compressed::TarGz.new(presigned_url: 'https://example.com/sample.tar.gz')
          expect(zi.size).to eq(389)
        end
      end

      describe '#file_entries' do
        it 'gives correct file entries for tar.gz' do

          stub_request(:get, 'https://example.com/sample.tar.gz')
            .with(
              headers: { 'Host' => 'example.com' }
            )
            .to_return(status: 200, body: File.binread('spec/fixtures/tar_gz/sample.tar.gz'),
                       headers: { 'Content-Type' => 'application/gzip' })

          tgz = Stash::Compressed::TarGz.new(presigned_url: 'https://example.com/sample.tar.gz')
          fe = tgz.file_entries

          fns = fe.map { |i| i[:file_name] }
          expect(fns).to include('test01.txt')
          expect(fns).to include('test02.txt')
          expect(fns).to include('test03.txt')

          uncomp = fe.map { |i| i[:uncompressed_size] }
          expect(uncomp).to include(17)
          expect(uncomp).to include(24)
          expect(uncomp).to include(52)
        end
      end

      it 'retries on http errors and succeeds later' do
        # how to stub different results on each request
        # https://stackoverflow.com/questions/33194363/multiple-calls-to-the-same-endpoint-with-different-results-in-webmock
        stub_request(:get, 'https://example.com/sample.tar.gz')
          .with(
            headers: { 'Host' => 'example.com' }
          )
          .to_return({ status: 500, body: 'fim', headers: { 'Content-Type' => 'application/gzip' } },
                     { status: 200, body: File.binread('spec/fixtures/tar_gz/sample.tar.gz'),
                       headers: { 'Content-Type' => 'application/gzip' } })

        tgz = Stash::Compressed::TarGz.new(presigned_url: 'https://example.com/sample.tar.gz')
        fe = tgz.file_entries(sleep_time: 0, tries: 2)

        fns = fe.map { |i| i[:file_name] }
        expect(fns).to include('test01.txt')
        expect(fns).to include('test02.txt')
        expect(fns).to include('test03.txt')

        uncomp = fe.map { |i| i[:uncompressed_size] }
        expect(uncomp).to include(17)
        expect(uncomp).to include(24)
        expect(uncomp).to include(52)
      end

      it 'fails on http errors' do
        stub_request(:get, 'https://example.com/sample.tar.gz')
          .with(
            headers: { 'Host' => 'example.com' }
          )
          .to_return({ status: 500, body: 'fim', headers: { 'Content-Type' => 'application/gzip' } },
                     { status: 200, body: File.binread('spec/fixtures/tar_gz/sample.tar.gz'),
                       headers: { 'Content-Type' => 'application/gzip' } })

        tgz = Stash::Compressed::TarGz.new(presigned_url: 'https://example.com/sample.tar.gz')
        expect { tgz.file_entries(sleep_time: 0, tries: 1) }.to raise_error(HTTP::Error)
      end
    end
  end
end
