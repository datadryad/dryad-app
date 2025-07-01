# == Schema Information
#
# Table name: stash_engine_generic_files
#
#  id                  :integer          not null, primary key
#  cloud_service       :string(191)
#  compressed_try      :integer          default(0)
#  description         :text(65535)
#  digest              :string(191)
#  digest_type         :string(8)
#  download_filename   :text(65535)
#  file_deleted_at     :datetime
#  file_state          :string(7)
#  original_filename   :text(65535)
#  original_url        :text(65535)
#  status_code         :integer
#  timed_out           :boolean          default(FALSE)
#  type                :string(191)
#  upload_content_type :text(65535)
#  upload_file_name    :text(65535)
#  upload_file_size    :bigint
#  upload_updated_at   :datetime
#  url                 :text(65535)
#  validated_at        :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  resource_id         :integer
#  storage_version_id  :integer
#
# Indexes
#
#  index_stash_engine_generic_files_on_download_filename  (download_filename)
#  index_stash_engine_generic_files_on_file_deleted_at    (file_deleted_at)
#  index_stash_engine_generic_files_on_file_state         (file_state)
#  index_stash_engine_generic_files_on_resource_id        (resource_id)
#  index_stash_engine_generic_files_on_status_code        (status_code)
#  index_stash_engine_generic_files_on_upload_file_name   (upload_file_name)
#  index_stash_engine_generic_files_on_url                (url)
#
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
                     email: 'lmuckenhaupt@datadryad.org',
                     tenant_id: 'ucop')

      @identifier = create(:identifier)
      @resource = create(:resource, user: @user, tenant_id: 'ucop', identifier: @identifier)
      @upload = create(:software_file,
                       resource: @resource,
                       file_state: 'created',
                       download_filename: 'foo.bar')

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
          end_with("/record/#{@copy2.deposition_id}/files/#{@upload.download_filename}?download=1")
      end
    end

    describe '#zenodo_presigned_url' do
      # TODO: fix this when we know what actually works at zenodo and they correct in their environments
      xit 'correctly creates a presigned (RATs) download url' do
        stub_get_existing_ds(deposition_id: @copy2.deposition_id)
        # stub_new_access_token
        item = @upload.zenodo_presigned_url
        expect(item).to include('/api/files/')
        expect(item).to include("/#{@upload.download_filename}")
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
        fu.update(url: "http://example.org/#{fu.download_filename}")
        value = fu.zenodo_replication_url
        expect(value).to eq("http://example.org/#{fu.download_filename}")
      end
    end

  end
end
