require 'fileutils'
require 'byebug'
require 'cgi'

module StashEngine
  describe DataFile do

    before(:each) do
      @user = create(:user,
                     first_name: 'Lisa',
                     last_name: 'Muckenhaupt',
                     email: 'lmuckenhaupt@ucop.edu',
                     tenant_id: 'ucop')

      @identifier = create(:identifier)
      @resource = create(:resource, user: @user, tenant_id: 'ucop', identifier: @identifier)
      @upload = create(:data_file,
                       resource: @resource,
                       file_state: 'created',
                       upload_file_name: 'foo.bar')
    end

    describe :version_file_created_in do
      it 'returns the resource version for newly created files' do
        expect(@upload.version_file_created_in).to eq(@resource.stash_version)
      end

      it 'returns the original version for versions created later' do
        original_version = @resource.stash_version
        new_resource = @resource.amoeba_dup
        expect(new_resource.stash_version).not_to eq(original_version) # just to be sure
        new_file_record = new_resource.data_files.take
        expect(new_file_record.file_state).to eq('copied') # just to be sure
        expect(new_file_record.version_file_created_in).to eq(original_version)
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
          create(:data_file, upload_file_name: 'noggin1.jpg', file_state: 'created', resource: @resource),
          create(:data_file, upload_file_name: 'noggin3.jpg', file_state: 'created', resource: @resource)
        ]

        @resource2 = create(:resource, user: @user, tenant_id: 'ucop', identifier: @identifier)
        @files2 = [
          create(:data_file, upload_file_name: 'noggin1.jpg', file_state: 'copied', resource: @resource2),
          create(:data_file, upload_file_name: 'noggin2.jpg', file_state: 'created', resource: @resource2),
          create(:data_file, upload_file_name: 'noggin3.jpg', file_state: 'deleted', resource: @resource2)
        ]
      end

      it 'deletes a file that was just created, from the database and s3' do
        expect(Stash::Aws::S3).to receive(:exists?).and_return(true)
        expect(Stash::Aws::S3).to receive(:delete_file)
        @files2[1].smart_destroy!
        @resource2.reload
        expect(@resource2.data_files.map(&:upload_file_name).include?('noggin2.jpg')).to eq(false)
      end

      it "deletes from database even if the s3 file doesn't exist" do
        expect(Stash::Aws::S3).to receive(:exists?).and_return(false)
        expect(Stash::Aws::S3).not_to receive(:delete_file)
        @files2[1].smart_destroy!
        @resource2.reload
        expect(@resource2.data_files.map(&:upload_file_name).include?('noggin2.jpg')).to eq(false)
      end

      it "doesn't add another Merritt deletion if one already exists" do
        @files2[2].smart_destroy!
        expect(@resource2.data_files.where(upload_file_name: 'noggin3.jpg').count).to eq(1)
      end

      it 'gets rid of extra deletions for the same files' do
        @files2 << create(:data_file, upload_file_name: 'noggin3.jpg', file_state: 'deleted', resource: @resource2)
        @files2[2].smart_destroy!
        expect(@resource2.data_files.where(upload_file_name: 'noggin3.jpg').count).to eq(1)
      end

      it 'removes a copied file and only keeps deletion if it is removed' do
        @files2[0].smart_destroy!
        expect(@resource2.data_files.where(upload_file_name: @files2[0].upload_file_name).count).to eq(1)
        expect(@resource2.data_files.where(upload_file_name: @files2[0].upload_file_name).first.file_state).to eq('deleted')
      end
    end

  end
end
