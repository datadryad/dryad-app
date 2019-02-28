require 'db_spec_helper'

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

    describe :sanitize_file_name do
      # Ensure that non-printable ACII control characters < 32 are sanitized
      it 'removes ASCII Control characters (0-31)' do
        (0..31).each do |i|
          expect(StashEngine::FileUpload.sanitize_file_name("#{i.chr}abc123")).to eql('abc123')
          expect(StashEngine::FileUpload.sanitize_file_name("abc123#{i.chr}")).to eql('abc123')

          if (9..13).cover?(i)
            expect(StashEngine::FileUpload.sanitize_file_name("abc#{i.chr}123")).to eql('abc 123')
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

      %w[| / \\ : ; " ' < > , ?].each do |chr|
        it "removes #{chr}" do
          expect(StashEngine::FileUpload.sanitize_file_name("#{chr}abc123")).to eql('abc123')
          expect(StashEngine::FileUpload.sanitize_file_name("abc#{chr}123")).to eql('abc123')
          expect(StashEngine::FileUpload.sanitize_file_name("abc123#{chr}")).to eql('abc123')
        end
      end

    end
  end
end
