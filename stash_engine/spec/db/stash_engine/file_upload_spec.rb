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
  end
end
