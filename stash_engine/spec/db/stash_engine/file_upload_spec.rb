require 'db_spec_helper'
require 'fileutils'
require_relative '../../../../spec_helpers/factory_helper'
require 'byebug'

module StashEngine
  describe FileUpload do
    attr_reader :user
    attr_reader :resource
    attr_reader :upload

    before(:each) do
      @user = StashEngine::User.create(
        first_name: 'Lisa',
        last_name: 'Muckenhaupt',
        email: 'lmuckenhaupt@ucop.edu',
        tenant_id: 'ucop'
      )

      @resource = Resource.create(user_id: user.id)
      resource.ensure_identifier('10.123/456')
      @upload = FileUpload.create(
        resource_id: resource.id,
        file_state: 'created',
        upload_file_name: 'foo.bar'
      )
    end

    describe :error_message do
      it 'returns the empty string for uploads with no URL' do
        expect(upload.error_message).to eq('')
      end

      it 'returns the empty string for uploads with status 200' do
        upload.url = 'http://example.org/foo.bar'
        upload.status_code = 200
        expect(upload.error_message).to eq('')
      end

      it 'returns a non-empty message for all other states' do
        upload.url = 'http://example.org/foo.bar'
        (100..599).each do |status|
          next if status == 200
          upload.status_code = status
          message = upload.error_message
          expect(message).not_to be_nil
          expect(message.strip).to eq(message)
          expect(message).not_to be_empty
        end
      end
    end

    describe :version_file_created_in do
      it 'returns the resource version for newly created files' do
        expect(upload.version_file_created_in).to eq(resource.stash_version)
      end

      it 'returns the original version for versions created later' do
        original_version = resource.stash_version
        new_resource = resource.amoeba_dup
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
        FileUtils.mkdir_p('tmp')
        @testfile = FileUtils.touch('tmp/noggin2.jpg').first # touch returns an array
        @files = [
          create(:file_upload, upload_file_name: 'noggin1.jpg', file_state: 'copied', resource_id: @resource.id),
          create(:file_upload, upload_file_name: 'noggin2.jpg', file_state: 'created', resource_id: @resource.id,
                               temp_file_path: File.expand_path(@testfile)),
          create(:file_upload, upload_file_name: 'noggin3.jpg', file_state: 'deleted', resource_id: @resource.id)
        ]
      end

      after(:each) do
        FileUtils.rm_rf('tmp')
      end

      it 'deletes a file that was just created, from the database and file system' do
        expect(::File.exist?(::File.expand_path(@testfile))).to eq(true)
        @files[1].smart_destroy!
        expect(::File.exist?(::File.expand_path(@testfile))).to eq(false)
        @resource.reload
        expect(@resource.file_uploads.map(&:upload_file_name).include?('noggin2.jpg')).to eq(false)
      end

      it "deletes from database even if the filesystem file doesn't exist" do
        FileUtils.rm_rf('tmp')
        @files[1].smart_destroy!
        @resource.reload
        expect(@resource.file_uploads.map(&:upload_file_name).include?('noggin2.jpg')).to eq(false)
      end

      it "doesn't add another Merritt deletion if one already exists" do
        @files[2].smart_destroy!
        expect(@resource.file_uploads.where(upload_file_name: 'noggin3.jpg').count).to eq(1)
      end

      it 'gets rid of extra deletions for the same files' do
        @files << create(:file_upload, upload_file_name: 'noggin3.jpg', file_state: 'deleted', resource_id: @resource.id)
        @files[2].smart_destroy!
        expect(@resource.file_uploads.where(upload_file_name: 'noggin3.jpg').count).to eq(1)
      end

      it 'removes a copied file and only keeps deletion if it is removed' do
        @files[0].smart_destroy!
        expect(@resource.file_uploads.where(upload_file_name: @files[0].upload_file_name).count).to eq(1)
        expect(@resource.file_uploads.where(upload_file_name: @files[0].upload_file_name).first.file_state).to eq('deleted')
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

    describe :calc_file_path do
      before(:each) do
        # need to hack in Rails.root because our test framework setup sucks and doesn't use rails testapp setup
        @rails_root = Dir.mktmpdir('rails_root')
        allow(Rails).to receive(:root).and_return(Pathname.new(@rails_root))
      end

      it 'returns path in uploads containing resource_id and filename' do
        cfp = @upload.calc_file_path
        expect(cfp.match(%r{/uploads/})).to be_truthy
        expect(cfp).to start_with(@rails_root.to_s)
        expect(cfp).to end_with(@upload.upload_file_name)
      end

      it 'returns nil if it is copied' do
        @upload.update(file_state: 'copied')
        @upload.reload
        expect(@upload.calc_file_path).to eq(nil)
      end

      it 'returns nil if it is deleted' do
        @upload.update(file_state: 'deleted')
        @upload.reload
        expect(@upload.calc_file_path).to eq(nil)
      end
    end
  end
end
