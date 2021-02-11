require 'fileutils'
require 'byebug'
require 'cgi'
require "#{Rails.root}/spec/lib/stash/zenodo_software/webmocks_helper"

module StashEngine
  describe SoftwareUpload do

    include Stash::ZenodoSoftware::WebmocksHelper

    before(:each) do
      @user = create(:user,
                     first_name: 'Lisa',
                     last_name: 'Muckenhaupt',
                     email: 'lmuckenhaupt@ucop.edu',
                     tenant_id: 'ucop')

      @identifier = create(:identifier)
      @resource = create(:resource, user: @user, tenant_id: 'ucop', identifier: @identifier)
      @upload = create(:software_upload,
                       resource: @resource,
                       file_state: 'created',
                       upload_file_name: 'foo.bar')

      @copy1 = create(:zenodo_copy, resource_id: @resource.id, identifier_id: @resource.identifier_id,
                                    state: 'finished', copy_type: 'software')

      @copy2 = create(:zenodo_copy, resource_id: @resource.id, identifier_id: @resource.identifier_id,
                                    state: 'finished', copy_type: 'software_publish')
    end

    describe '#calc_s3_path' do
      it 'returns a path for zenodo files' do
        expect(@upload.calc_s3_path).to \
          end_with("#{@resource.id}/sfw/#{@upload.upload_file_name}")
      end
    end

    describe '#public_zenodo_download_url' do
      it 'correctly creates a public download url' do
        expect(@upload.public_zenodo_download_url).to \
          end_with("/record/#{@copy2.deposition_id}/files/#{@upload.upload_file_name}?download=1")
      end
    end

    describe '#zenodo_presigned_url' do
      it 'correctly creates a presigned (RATs) download url' do
        stub_get_existing_ds(deposition_id: @copy2.deposition_id)
        item = @upload.zenodo_presigned_url
        expect(item).to include('/api/files/')
        expect(item).to include("/#{@upload.upload_file_name}")
        expect(item).to include('token=')
      end
    end
  end
end
