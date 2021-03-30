require 'fileutils'
require 'byebug'
require 'cgi'
require Rails.root.join('stash/stash_engine/lib/stash/aws/s3')

module StashEngine
  describe FileUpload do

    before(:each) do
      @user = create(:user,
                     first_name: 'Lisa',
                     last_name: 'Muckenhaupt',
                     email: 'lmuckenhaupt@ucop.edu',
                     tenant_id: 'ucop')

      @identifier = create(:identifier)
      @resource = create(:resource, user: @user, tenant_id: 'ucop', identifier: @identifier)
      @upload = create(:file_upload,
                       resource: @resource,
                       file_state: 'created',
                       upload_file_name: 'foo.bar')
    end

    describe :error_message do
      it 'returns the empty string for uploads with no URL' do
        expect(@upload.error_message).to eq('')
      end

      it 'returns the empty string for uploads with status 200' do
        @upload.url = 'http://example.org/foo.bar'
        @upload.status_code = 200
        expect(@upload.error_message).to eq('')
      end

      it 'returns a non-empty message for all other states' do
        @upload.url = 'http://example.org/foo.bar'
        (100..599).each do |status|
          next if status == 200

          @upload.status_code = status
          message = @upload.error_message
          expect(message).not_to be_nil
          expect(message.strip).to eq(message)
          expect(message).not_to be_empty
        end
      end
    end

    describe :version_file_created_in do
      it 'returns the resource version for newly created files' do
        expect(@upload.version_file_created_in).to eq(@resource.stash_version)
      end

      it 'returns the original version for versions created later' do
        original_version = @resource.stash_version
        new_resource = @resource.amoeba_dup
        expect(new_resource.stash_version).not_to eq(original_version) # just to be sure
        new_file_record = new_resource.file_uploads.take
        expect(new_file_record.file_state).to eq('copied') # just to be sure
        expect(new_file_record.version_file_created_in).to eq(original_version)
      end
    end

    describe :digests do
      it 'identifies item without digest' do
        expect(@upload.digest?).to be false
      end

      it 'identifies item without digest type' do
        @upload.update(digest: '12345')
        expect(@upload.digest?).to be false
      end

      it 'identifies item without digest' do
        @upload.update(digest_type: 'md5')
        expect(@upload.digest?).to be false
      end

      it 'identifies item with complete digest info' do
        @upload.update(digest_type: 'md5', digest: '12345')
        expect(@upload.digest?).to be true
      end
    end

    describe :merritt_express_url do
      before(:each) do
        @tricky_ark = 'ark%3A%2F12345/38568'
        allow_any_instance_of(Resource).to receive(:merritt_protodomain_and_local_id).and_return(
          ['https://merritt.example.com', @tricky_ark]
        )
      end

      it 'creates url with the merritt-express host' do
        expect(@upload.merritt_express_url).to start_with(APP_CONFIG.merritt_express_base_url)
      end

      it 'creates url that ends with the filename' do
        expect(@upload.merritt_express_url).to end_with(@upload.upload_file_name)
      end

      it "has decoded ark because M.E. doesn't work right with ark encoded" do
        expect(@upload.merritt_express_url).to include(CGI.unescape(@tricky_ark))
      end

      it 'includes the /dv/ and version in the url' do
        expect(@upload.merritt_express_url).to include('/dv/1/')
      end
    end

    describe '#smart_destroy!' do

      before(:each) do
        @files = [
          create(:file_upload, upload_file_name: 'noggin1.jpg', file_state: 'created', resource: @resource),
          create(:file_upload, upload_file_name: 'noggin3.jpg', file_state: 'created', resource: @resource)
        ]

        @resource2 = create(:resource, user: @user, tenant_id: 'ucop', identifier: @identifier)
        @files2 = [
          create(:file_upload, upload_file_name: 'noggin1.jpg', file_state: 'copied', resource: @resource2),
          create(:file_upload, upload_file_name: 'noggin2.jpg', file_state: 'created', resource: @resource2),
          create(:file_upload, upload_file_name: 'noggin3.jpg', file_state: 'deleted', resource: @resource2)
        ]
      end

      it 'deletes a file that was just created, from the database and s3' do
        expect(Stash::Aws::S3).to receive(:exists?).and_return(true)
        expect(Stash::Aws::S3).to receive(:delete_file)
        @files2[1].smart_destroy!
        @resource2.reload
        expect(@resource2.file_uploads.map(&:upload_file_name).include?('noggin2.jpg')).to eq(false)
      end

      it "deletes from database even if the s3 file doesn't exist" do
        expect(Stash::Aws::S3).to receive(:exists?).and_return(false)
        expect(Stash::Aws::S3).not_to receive(:delete_file)
        @files2[1].smart_destroy!
        @resource2.reload
        expect(@resource2.file_uploads.map(&:upload_file_name).include?('noggin2.jpg')).to eq(false)
      end

      it "doesn't add another Merritt deletion if one already exists" do
        @files2[2].smart_destroy!
        expect(@resource2.file_uploads.where(upload_file_name: 'noggin3.jpg').count).to eq(1)
      end

      it 'gets rid of extra deletions for the same files' do
        @files2 << create(:file_upload, upload_file_name: 'noggin3.jpg', file_state: 'deleted', resource: @resource2)
        @files2[2].smart_destroy!
        expect(@resource2.file_uploads.where(upload_file_name: 'noggin3.jpg').count).to eq(1)
      end

      it 'removes a copied file and only keeps deletion if it is removed' do
        @files2[0].smart_destroy!
        expect(@resource2.file_uploads.where(upload_file_name: @files2[0].upload_file_name).count).to eq(1)
        expect(@resource2.file_uploads.where(upload_file_name: @files2[0].upload_file_name).first.file_state).to eq('deleted')
      end
    end

    describe :sanitize_file_name do
      # Ensure that non-printable ACII control characters < 32 are sanitized
      it 'removes ASCII Control characters (0-31)' do
        (0..31).each do |i|
          expect(StashEngine::FileUpload.sanitize_file_name("#{i.chr}abc123")).to eql('abc123')
          expect(StashEngine::FileUpload.sanitize_file_name("abc123#{i.chr}")).to eql('abc123')

          # Zaru replaces characters 9-13 with a space
          if (9..13).cover?(i)
            expect(StashEngine::FileUpload.sanitize_file_name("abc#{i.chr}123")).to eql('abc_123')
          else
            expect(StashEngine::FileUpload.sanitize_file_name("abc#{i.chr}123")).to eql('abc123')
          end
        end
      end

      it 'removes ASCII Delete character (127)' do
        expect(StashEngine::FileUpload.sanitize_file_name("#{127.chr}abc123")).to eql('abc123')
        expect(StashEngine::FileUpload.sanitize_file_name("abc123#{127.chr}")).to eql('abc123')
        expect(StashEngine::FileUpload.sanitize_file_name("abc#{127.chr}123")).to eql('abc123')
      end

      it 'replaces spaces with underscores' do
        expect(StashEngine::FileUpload.sanitize_file_name('abc 123')).to eql('abc_123')
        expect(StashEngine::FileUpload.sanitize_file_name('abc  123')).to eql('abc_123')
      end

      it 'removes trailing and leading spaces' do
        expect(StashEngine::FileUpload.sanitize_file_name('  abc123')).to eql('abc123')
        expect(StashEngine::FileUpload.sanitize_file_name('abc123  ')).to eql('abc123')
      end

      %w[| / \\ : ; " ' < > , ?].each do |chr|
        it "removes #{chr}" do
          expect(StashEngine::FileUpload.sanitize_file_name("#{chr}abc123")).to eql('abc123')
          expect(StashEngine::FileUpload.sanitize_file_name("abc#{chr}123")).to eql('abc123')
          expect(StashEngine::FileUpload.sanitize_file_name("abc123#{chr}")).to eql('abc123')
        end
      end

      it 'does not remove foreign characters' do
        expect(StashEngine::FileUpload.sanitize_file_name('abc𠝹Ѭμ123')).to eql('abc𠝹Ѭμ123')
      end

      it 'does not remove emoji characters' do
        expect(StashEngine::FileUpload.sanitize_file_name('abc😂123')).to eql('abc😂123')
      end

    end

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

      it "doubly-encodes any # signs in filenames because otherwise they work in Merritt with standard encoding" do
        @upload.upload_file_name = '#1 in the world'
        expect(@upload.merritt_presign_info_url).to eq(
          'https://merritt.example.com/api/presign-file/ark%3A%2F12345%2F38568/1/producer%2F%25231%20in%20the%20world?no_redirect=true'
        )
      end

      it "doubly-encodes any % signs in the filenames because Merritt doesn't accept this in a standards-compliant encoding" do
        @upload.upload_file_name = 'my%fun-r-file.r'
        expect(@upload.merritt_presign_info_url).to eq(
          'https://merritt.example.com/api/presign-file/ark%3A%2F12345%2F38568/1/producer%2Fmy%2525fun-r-file.r?no_redirect=true'
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
