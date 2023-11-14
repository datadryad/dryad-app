require 'fileutils'
require 'byebug'
require 'cgi'
require "#{Rails.root}/spec/lib/stash/zenodo_software/webmocks_helper"

module StashEngine
  describe SoftwareFile do
    include Stash::ZenodoSoftware::WebmocksHelper

    before(:each) do
      @user = create(:user,
                     first_name: 'Lisa',
                     last_name: 'Muckenhaupt',
                     email: 'lmuckenhaupt@ucop.edu',
                     tenant_id: 'ucop')

      @identifier = create(:identifier)
      @resource = create(:resource, user: @user, tenant_id: 'ucop', identifier: @identifier)
      @upload = create(:software_file,
                       resource: @resource,
                       file_state: 'created',
                       upload_file_name: 'foo.bar')

      @copy1 = create(:zenodo_copy, resource_id: @resource.id, identifier_id: @resource.identifier_id,
                                    state: 'finished', copy_type: 'software')

      @copy2 = create(:zenodo_copy, resource_id: @resource.id, identifier_id: @resource.identifier_id,
                                    state: 'finished', copy_type: 'software_publish')
    end

    describe '#s3_staged_path' do
      it 'returns a path for zenodo files' do
        expect(@upload.s3_staged_path).to \
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
      # TODO: fix this when we know what actually works at zenodo and they correct in their environments
      xit 'correctly creates a presigned (RATs) download url' do
        stub_get_existing_ds(deposition_id: @copy2.deposition_id)
        # stub_new_access_token
        item = @upload.zenodo_presigned_url
        expect(item).to include('/api/files/')
        expect(item).to include("/#{@upload.upload_file_name}")
        expect(item).to include('token=')
      end
    end

    describe '#zenodo_replication_url' do
      it 'replicates from s3 if direct upload' do
        fu = @resource.software_files.first
        expect(fu).to receive(:s3_staged_presigned_url).and_return(nil)
        fu.zenodo_replication_url
      end

      it 'replicates from url if server url upload' do
        fu = @resource.software_files.first
        fu.update(url: "http://example.org/#{fu.upload_file_name}")
        value = fu.zenodo_replication_url
        expect(value).to eq("http://example.org/#{fu.upload_file_name}")
      end
    end

  end
end
