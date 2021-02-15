require 'byebug'
require 'fileutils'
require 'stash/zenodo_software'

require 'rails_helper'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module ZenodoSoftware
    RSpec.describe FileDownload do

      before(:each) do
        @resource = create(:resource)

        # make some random file contents for testing
        @file_contents = []
        0.upto(2) do
          @file_contents.push(Random.new.bytes(rand(1000)).b)
        end

        @software_direct_upload = create(:software_upload, upload_file_size: @file_contents.first.length, resource: @resource)
        @software_http_upload = create(:software_upload, upload_file_size: @file_contents.second.length,
                                                         url: 'http://example.org/example', resource: @resource)

        FileUtils.mkdir_p(@resource.software_upload_dir)
        ::File.open(@software_direct_upload.calc_file_path, 'wb') { |f| f.write(@file_contents.first) }
      end

      after(:each) do
        FileUtils.rm_rf(@resource.software_upload_dir)
      end

      describe '#check_file_exists' do
        xit 'raises no exception if the direct upload file exists that should' do
          f = Stash::ZenodoSoftware::FileDownload.new(file_obj: @software_direct_upload)
          expect { f.check_file_exists }.not_to raise_exception
        end

        xit "raises an exception if the file that should exist doesn't" do
          FileUtils.rm(@software_direct_upload.calc_file_path)
          f = Stash::ZenodoSoftware::FileDownload.new(file_obj: @software_direct_upload)
          expect { f.check_file_exists }.to raise_exception(Stash::ZenodoSoftware::FileError)
        end
      end

      describe '#check_digest' do
        xit 'ignores items with unknown digest type' do
          f = Stash::ZenodoSoftware::FileDownload.new(file_obj: @software_direct_upload)
          expect { f.check_digest }.not_to raise_exception
        end

        xit 'works with correct md5' do
          digest = Digest::MD5.file(@software_direct_upload.calc_file_path).hexdigest
          @software_direct_upload.update(digest: digest, digest_type: 'md5')
          f = Stash::ZenodoSoftware::FileDownload.new(file_obj: @software_direct_upload)
          expect { f.check_digest }.not_to raise_exception
        end

        xit 'catches bad md5' do
          digest = Digest::MD5.hexdigest(@file_contents.second)
          @software_direct_upload.update(digest: digest, digest_type: 'md5')
          f = Stash::ZenodoSoftware::FileDownload.new(file_obj: @software_direct_upload)
          expect { f.check_digest }.to raise_exception(Stash::ZenodoSoftware::FileError)
        end

        xit 'works with correct sha-1' do
          digest = Digest::SHA1.file(@software_direct_upload.calc_file_path).hexdigest
          @software_direct_upload.update(digest: digest, digest_type: 'sha-1')
          f = Stash::ZenodoSoftware::FileDownload.new(file_obj: @software_direct_upload)
          expect { f.check_digest }.not_to raise_exception
        end

        xit 'catches bad sha-1' do
          digest = Digest::SHA1.hexdigest(@file_contents.second)
          @software_direct_upload.update(digest: digest, digest_type: 'sha-1')
          f = Stash::ZenodoSoftware::FileDownload.new(file_obj: @software_direct_upload)
          expect { f.check_digest }.to raise_exception(Stash::ZenodoSoftware::FileError)
        end

        xit 'works with correct sha-256' do
          digest = Digest::SHA256.file(@software_direct_upload.calc_file_path).hexdigest
          @software_direct_upload.update(digest: digest, digest_type: 'sha-256')
          f = Stash::ZenodoSoftware::FileDownload.new(file_obj: @software_direct_upload)
          expect { f.check_digest }.not_to raise_exception
        end

        xit 'catches bad sha-256' do
          digest = Digest::SHA256.hexdigest(@file_contents.second)
          @software_direct_upload.update(digest: digest, digest_type: 'sha-256')
          f = Stash::ZenodoSoftware::FileDownload.new(file_obj: @software_direct_upload)
          expect { f.check_digest }.to raise_exception(Stash::ZenodoSoftware::FileError)
        end

        xit 'works with correct sha-384' do
          digest = Digest::SHA384.file(@software_direct_upload.calc_file_path).hexdigest
          @software_direct_upload.update(digest: digest, digest_type: 'sha-384')
          f = Stash::ZenodoSoftware::FileDownload.new(file_obj: @software_direct_upload)
          expect { f.check_digest }.not_to raise_exception
        end

        xit 'catches bad sha-384' do
          digest = Digest::SHA384.hexdigest(@file_contents.second)
          @software_direct_upload.update(digest: digest, digest_type: 'sha-384')
          f = Stash::ZenodoSoftware::FileDownload.new(file_obj: @software_direct_upload)
          expect { f.check_digest }.to raise_exception(Stash::ZenodoSoftware::FileError)
        end

        xit 'works with correct sha-512' do
          digest = Digest::SHA512.file(@software_direct_upload.calc_file_path).hexdigest
          @software_direct_upload.update(digest: digest, digest_type: 'sha-512')
          f = Stash::ZenodoSoftware::FileDownload.new(file_obj: @software_direct_upload)
          expect { f.check_digest }.not_to raise_exception
        end

        xit 'catches bad sha-512' do
          digest = Digest::SHA512.hexdigest(@file_contents.second)
          @software_direct_upload.update(digest: digest, digest_type: 'sha-512')
          f = Stash::ZenodoSoftware::FileDownload.new(file_obj: @software_direct_upload)
          expect { f.check_digest }.to raise_exception(Stash::ZenodoSoftware::FileError)
        end
      end

      describe '#download' do
        xit 'successfully downloads a file from the internet' do
          stub_request(:get, 'http://example.org/example')
            .to_return(status: 200, body: @file_contents.second, headers: {})

          f = Stash::ZenodoSoftware::FileDownload.new(file_obj: @software_http_upload)
          expect { f.download }.not_to raise_exception
          expect(::File.exist?(@software_http_upload.calc_file_path)).to eq(true)
          expect(::File.open(@software_http_upload.calc_file_path, 'rb', &:read)).to eq(@file_contents.second)
        end

        xit 'handles an unsuccessful response from the web server and raises an error' do
          stub_request(:get, 'http://example.org/example')
            .to_return(status: 404, body: '', headers: {})

          f = Stash::ZenodoSoftware::FileDownload.new(file_obj: @software_http_upload)
          expect { f.download }.to raise_exception(Stash::ZenodoSoftware::FileError)
          expect(::File.exist?(@software_http_upload.calc_file_path)).to eq(false)
        end

        xit 'handles an unsuccessful response due to HTTP::Error' do
          stub_request(:get, 'http://example.org/example').to_raise(HTTP::Error)

          f = Stash::ZenodoSoftware::FileDownload.new(file_obj: @software_http_upload)
          expect { f.download }.to raise_exception(Stash::ZenodoSoftware::FileError)
          expect(::File.exist?(@software_http_upload.calc_file_path)).to eq(false)
        end

        xit 'handles an unsuccessful response due to timeout' do
          stub_request(:get, 'http://example.org/example').to_timeout

          f = Stash::ZenodoSoftware::FileDownload.new(file_obj: @software_http_upload)
          expect { f.download }.to raise_exception(Stash::ZenodoSoftware::FileError)
          expect(::File.exist?(@software_http_upload.calc_file_path)).to eq(false)
        end
      end
    end
  end
end
