require 'fileutils'
require 'byebug'
require 'cgi'
require Rails.root.join('stash/stash_engine/lib/stash/aws/s3')

module StashEngine
  describe FileUpload do

    describe :calc_s3_path do
      it 'returns path in uploads containing resource_id and filename' do
        cs3p = @upload.calc_s3_path
        expect(cs3p).to end_with('/data/foo.bar')
        expect(cs3p).to include(@resource.id.to_s)
      end

      it 'returns nil if it is copied' do
        @upload.update(file_state: 'copied')
        @upload.reload
        expect(@upload.calc_s3_path).to eq(nil)
      end

      it 'returns nil if it is deleted' do
        @upload.update(file_state: 'deleted')
        @upload.reload
        expect(@upload.calc_s3_path).to eq(nil)
      end
    end

    describe :merritt_presign_info_url do
      before(:each) do
        allow_any_instance_of(Resource).to receive(:merritt_protodomain_and_local_id).and_return(
          ['https://merritt.example.com', 'ark%3A%2F12345%2F38568']
        )
      end

      it 'returns the url to get the merritt presigned url to s3' do
        expect(@upload.merritt_presign_info_url).to eq(
          'https://merritt.example.com/api/presign-file/ark%3A%2F12345%2F38568/1/producer%2Ffoo.bar?no_redirect=true'
        )
      end

      it 'doubly-encodes any # signs in filenames because otherwise they prematurely cut off in Merritt' do
        @upload.upload_file_name = '#1 in the world'
        expect(@upload.merritt_presign_info_url).to eq(
          'https://merritt.example.com/api/presign-file/ark%3A%2F12345%2F38568/1/producer%2F%25231%20in%20the%20world?no_redirect=true'
        )
      end
    end

    describe :merritt_s3_presigned_url do
      before(:each) do
        allow_any_instance_of(Resource).to receive(:merritt_protodomain_and_local_id).and_return(
          ['https://merritt.example.com', 'ark%3A%2F12345%2F38568']
        )

        tenant = { repository: { username: 'martinka', password: '123987xurp' }.to_ostruct }.to_ostruct
        allow(Tenant).to receive(:find).with('ucop').and_return(tenant)
      end

      it 'raises Stash::Download::MerrittError for missing resource.tenant' do
        @upload.resource.update(tenant_id: nil)
        @upload.resource.reload
        expect { @upload.merritt_s3_presigned_url }.to raise_error(Stash::Download::MerrittError)
      end

      it 'raises Stash::Download::MerrittError for unsuccessful response from Merritt' do
        stub_request(:get, 'https://merritt.example.com/api/presign-file/ark:%2F12345%2F38568/1/producer%2Ffoo.bar?no_redirect=true')
          .with(
            headers: {
              'Authorization' => 'Basic bWFydGlua2E6MTIzOTg3eHVycA==',
              'Host' => 'merritt.example.com'
            }
          )
          .to_return(status: 404, body: '[]', headers: { 'Content-Type': 'application/json' })
        expect { @upload.merritt_s3_presigned_url }.to raise_error(Stash::Download::MerrittError)
      end

      it 'returns a URL based on json response and url in the data' do
        stub_request(:get, 'https://merritt.example.com/api/presign-file/ark:%2F12345%2F38568/1/producer%2Ffoo.bar?no_redirect=true')
          .with(
            headers: {
              'Authorization' => 'Basic bWFydGlua2E6MTIzOTg3eHVycA==',
              'Host' => 'merritt.example.com'
            }
          )
          .to_return(status: 200, body: '{"url": "http://my.presigned.url/is/great/39768945"}',
                     headers: { 'Content-Type': 'application/json' })

        expect(@upload.merritt_s3_presigned_url).to eq('http://my.presigned.url/is/great/39768945')
      end

      it "it doesn't create a mangled URL because http.rb has modified the URL with some foreign characters so it no longer matches" do
        str = 'javois%CC%8C_et_al_data.xls'
        fn = CGI.unescape(str)
        stub_request(:get, "https://merritt.example.com/api/presign-file/ark:%2F12345%2F38568/1/producer%2F#{str}?no_redirect=true")
          .with(
            headers: {
              'Authorization' => 'Basic bWFydGlua2E6MTIzOTg3eHVycA==',
              'Host' => 'merritt.example.com'
            }
          )
          .to_return(status: 200, body: '{"url": "http://my.presigned.url/is/great/34snak"}',
                     headers: { 'Content-Type': 'application/json' })
        @upload2 = create(:file_upload,
                          resource: @resource,
                          file_state: 'created',
                          upload_file_name: fn)
        expect(@upload2.merritt_s3_presigned_url).to eq('http://my.presigned.url/is/great/34snak') # returned the value from matching the url
      end
    end

    describe '#in_previous_version' do
      before(:each) do
        @files = [
          create(:file_upload, upload_file_name: 'noggin1.jpg', file_state: 'created', resource_id: @resource.id),
          create(:file_upload, upload_file_name: 'noggin3.jpg', file_state: 'created', resource_id: @resource.id)
        ]

        @resource2 = create(:resource, user: @user, tenant_id: 'ucop', identifier: @identifier)

        @files2 = [
          create(:file_upload, upload_file_name: 'noggin1.jpg', file_state: 'copied', resource_id: @resource2.id),
          create(:file_upload, upload_file_name: 'noggin2.jpg', file_state: 'created', resource_id: @resource2.id),
          create(:file_upload, upload_file_name: 'noggin3.jpg', file_state: 'deleted', resource_id: @resource2.id)
        ]
      end

      it 'returns false for version 1' do
        expect(@files[0].in_previous_version?).to eq(false)
        expect(@files[1].in_previous_version?).to eq(false)
      end

      it 'returns true for a file that existed previously' do
        expect(@files2[0].in_previous_version?).to eq(true)
        expect(@files2[2].in_previous_version?).to eq(true)
      end

      it "returns false for file that didn't exist previously" do
        expect(@files2[1].in_previous_version?).to eq(false)
      end
    end

    describe '#zenodo_replication_url' do
      it 'always replicates urls from merritt for Zenodo data copies' do
        fu = @resource.file_uploads.first
        expect(fu).to receive(:merritt_s3_presigned_url).and_return(nil)
        fu.zenodo_replication_url
      end
    end
  end
end
