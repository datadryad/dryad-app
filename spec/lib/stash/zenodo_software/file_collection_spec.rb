require 'stash/zenodo_software'
require 'fileutils'

require 'rails_helper'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module ZenodoSoftware
    RSpec.describe FileCollection do

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

        stub_request(:get, 'http://example.org/example')
          .to_return(status: 200, body: @file_contents.second, headers: {})
      end

      after(:each) do
        FileUtils.rm_rf(@resource.software_upload_dir)
      end

      xit 'uses all the methods to ensure files are available locally' do
        # individual methods of the ZenodoSoftware::File class are tested there
        fc = Stash::ZenodoSoftware::FileCollection.new(resource: @resource)
        expect { fc.ensure_local_files }.not_to raise_exception
        expect(Dir["#{@resource.software_upload_dir}/*"].length).to eq(2)
      end

      xit 'removes files and directory for cleanup_files' do
        fc = Stash::ZenodoSoftware::FileCollection.new(resource: @resource)
        fc.cleanup_files
        expect(Dir.exist?(@resource.software_upload_dir)).to eq(false)
      end
    end
  end
end
