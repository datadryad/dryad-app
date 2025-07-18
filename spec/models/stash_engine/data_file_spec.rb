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
#  index_stash_engine_generic_files_on_download_filename  (download_filename)
#  index_stash_engine_generic_files_on_file_deleted_at    (file_deleted_at)
#  index_stash_engine_generic_files_on_file_state         (file_state)
#  index_stash_engine_generic_files_on_resource_id        (resource_id)
#  index_stash_engine_generic_files_on_status_code        (status_code)
#  index_stash_engine_generic_files_on_upload_file_name   (upload_file_name)
#  index_stash_engine_generic_files_on_url                (url)
require 'fileutils'
require 'byebug'
require 'cgi'

module StashEngine
  describe DataFile do

    before(:each) do
      Timecop.travel(Time.now.utc - 3.hours)
      @user = create(:user,
                     first_name: 'Lisa',
                     last_name: 'Muckenhaupt',
                     email: 'lmuckenhaupt@datadryad.org',
                     tenant_id: 'ucop')

      @identifier = create(:identifier)
      @resource = create(:resource, user: @user, tenant_id: 'ucop', identifier: @identifier)
      @upload = create(:data_file,
                       resource: @resource,
                       file_state: 'created',
                       download_filename: 'foo.bar')
      Timecop.return
    end

    describe :version_file_created_in do
      it 'returns the resource version for newly created files' do
        expect(@upload.version_file_created_in).to eq(@resource.stash_version)
      end

      it 'returns the original version for versions created later' do
        original_version = @resource.stash_version
        new_resource = @resource.amoeba_dup
        expect(new_resource.stash_version).not_to eq(original_version) # just to be sure
        new_resource.save
        new_file_record = new_resource.data_files.take
        expect(new_file_record.file_state).to eq('copied') # just to be sure
        expect(new_file_record.version_file_created_in).to eq(original_version)
      end
    end

    describe '#smart_destroy!' do

      before(:each) do
        @files = [
          create(:data_file, download_filename: 'noggin1.jpg', file_state: 'created', resource: @resource),
          create(:data_file, download_filename: 'noggin3.jpg', file_state: 'created', resource: @resource)
        ]

        @resource2 = create(:resource, user: @user, tenant_id: 'ucop', identifier: @identifier)
        @files2 = [
          create(:data_file, download_filename: 'noggin1.jpg', file_state: 'copied', resource: @resource2),
          create(:data_file, download_filename: 'noggin2.jpg', file_state: 'created', resource: @resource2),
          create(:data_file, download_filename: 'noggin3.jpg', file_state: 'deleted', resource: @resource2)
        ]
      end

      it 'deletes a file that was just created, from the database and s3' do
        expect_any_instance_of(Stash::Aws::S3).to receive(:exists?).and_return(true)
        expect_any_instance_of(Stash::Aws::S3).to receive(:delete_file)
        @files2[1].smart_destroy!
        @resource2.reload
        expect(@resource2.data_files.map(&:download_filename).include?('noggin2.jpg')).to eq(false)
      end

      it "deletes from database even if the s3 file doesn't exist" do
        expect_any_instance_of(Stash::Aws::S3).to receive(:exists?).and_return(false)
        expect_any_instance_of(Stash::Aws::S3).not_to receive(:delete_file)
        @files2[1].smart_destroy!
        @resource2.reload
        expect(@resource2.data_files.map(&:download_filename).include?('noggin2.jpg')).to eq(false)
      end

      it "doesn't add another Merritt deletion if one already exists" do
        @files2[2].smart_destroy!
        expect(@resource2.data_files.where(download_filename: 'noggin3.jpg').count).to eq(1)
      end

      it 'gets rid of extra deletions for the same files' do
        @files2 << create(:data_file, download_filename: 'noggin3.jpg', file_state: 'deleted', resource: @resource2)
        @files2[2].smart_destroy!
        expect(@resource2.data_files.where(download_filename: 'noggin3.jpg').count).to eq(1)
      end

      it 'removes a copied file and only keeps deletion if it is removed' do
        @files2[0].smart_destroy!
        expect(@resource2.data_files.where(download_filename: @files2[0].download_filename).count).to eq(1)
        expect(@resource2.data_files.where(download_filename: @files2[0].download_filename).first.file_state).to eq('deleted')
      end

      it 'makes merritt remove request for a file of different capitalization' do
        changed_case = @resource2.data_files.where(download_filename: 'noggin3.jpg').first
        changed_case.update(download_filename: 'NoGgIn3.JpG')
        changed_case.smart_destroy!
        destroy_file = @resource2.data_files.where(file_state: 'deleted').first

        expect(destroy_file.download_filename).to eq('noggin3.jpg')

        # not NoGgIn3.JpG for the current version and that is just gone
        expect(@resource2.data_files.where(download_filename: 'noggin3.jpg').count).to eq(1) # only destroy file and not former file
      end

      it 'clears frictionless reports' do
        allow_any_instance_of(Stash::Aws::S3).to receive(:exists?).and_return(false)

        create(:frictionless_report, generic_file: @files2[1])
        expect { @files2[1].smart_destroy! }.to change(FrictionlessReport, :count).by(-1)
      end

      it 'clears PII scan reports' do
        allow_any_instance_of(Stash::Aws::S3).to receive(:exists?).and_return(false)

        create(:sensitive_data_report, generic_file: @files2[1])
        expect { @files2[1].smart_destroy! }.to change(SensitiveDataReport, :count).by(-1)
      end
    end

    describe :s3_staged_path do
      it 'returns path in uploads containing resource_id and filename' do
        cs3p = @upload.s3_staged_path
        expect(cs3p).to end_with("/data/#{@upload.upload_file_name}")
        expect(cs3p).to include(@resource.id.to_s)
      end

      it 'returns nil if it is copied' do
        @upload.update(file_state: 'copied')
        @upload.reload
        expect(@upload.s3_staged_path).to eq(nil)
      end

      it 'returns nil if it is deleted' do
        @upload.update(file_state: 'deleted')
        @upload.reload
        expect(@upload.s3_staged_path).to eq(nil)
      end
    end

    describe :merritt_presign_info_url do
      before(:each) do
        allow_any_instance_of(Resource).to receive(:merritt_protodomain_and_local_id).and_return(
          ['https://merritt.example.com', 'ark%3A%2F12345%2F38568']
        )
      end

      it 'returns the url to get the merritt presigned url to s3' do
        @upload.upload_file_name = 'foo.bar'
        expect(@upload.merritt_presign_info_url).to eq(
          'https://merritt.example.com/api/presign-file/ark%3A%2F12345%2F38568/1/producer%2Ffoo.bar?no_redirect=true'
        )
      end

      it 'doubly-encodes arks and filenames when there are # signs in filename because otherwise they prematurely cut off in Merritt' do
        @upload.upload_file_name = '#1 in the world'
        expect(@upload.merritt_presign_info_url).to eq(
          'https://merritt.example.com/api/presign-file/ark%253A%252F12345%252F38568/1/producer%252F%25231%2520in%2520the%2520world?no_redirect=true'
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

      it 'raises Stash::Download::S3CustomError for missing resource.tenant' do
        @upload.resource.update(tenant_id: nil)
        @upload.resource.reload
        expect { @upload.merritt_s3_presigned_url }.to raise_error(Stash::Download::S3CustomError)
      end

      it 'raises Stash::Download::S3CustomError for unsuccessful response' do
        stub_request(:get, "https://merritt.example.com/api/presign-file/ark:%2F12345%2F38568/1/producer%2F#{@upload.upload_file_name}?no_redirect=true")
          .with(
            headers: {
              'Authorization' => 'Basic aG9yc2VjYXQ6TXlIb3JzZUNhdFBhc3N3b3Jk',
              'Host' => 'merritt.example.com'
            }
          )
          .to_return(status: 404, body: '[]', headers: { 'Content-Type': 'application/json' })
        expect { @upload.merritt_s3_presigned_url }.to raise_error(Stash::Download::S3CustomError)
      end

      it 'returns a URL based on json response and url in the data' do
        stub_request(:get, "https://merritt.example.com/api/presign-file/ark:%2F12345%2F38568/1/producer%2F#{@upload.upload_file_name}?no_redirect=true")
          .with(
            headers: {
              'Authorization' => 'Basic aG9yc2VjYXQ6TXlIb3JzZUNhdFBhc3N3b3Jk',
              'Host' => 'merritt.example.com'
            }
          )
          .to_return(status: 200, body: '{"url": "http://my.presigned.url/is/great/39768945"}',
                     headers: { 'Content-Type': 'application/json' })

        expect(@upload.merritt_s3_presigned_url).to eq('http://my.presigned.url/is/great/39768945')
      end
    end

    # even though this exists in the base class, the versioning should only be used in individual classes
    describe '#in_previous_version' do
      before(:each) do
        @files = [
          create(:data_file, download_filename: 'noggin1.jpg', file_state: 'created', resource_id: @resource.id),
          create(:data_file, download_filename: 'noggin3.jpg', file_state: 'created', resource_id: @resource.id)
        ]

        @resource2 = create(:resource, user: @user, tenant_id: 'ucop', identifier: @identifier)

        @files2 = [
          create(:data_file, download_filename: 'noggin1.jpg', file_state: 'copied', resource_id: @resource2.id),
          create(:data_file, download_filename: 'noggin2.jpg', file_state: 'created', resource_id: @resource2.id),
          create(:data_file, download_filename: 'noggin3.jpg', file_state: 'deleted', resource_id: @resource2.id)
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
        fu = @resource.data_files.first
        expect(fu).to receive(:s3_permanent_presigned_url).and_return(nil)
        fu.zenodo_replication_url
      end
    end

    describe '#text_preview' do
      before(:each) do
        @upload2 = create(:data_file,
                          digest: 'fake_digest',
                          resource: @resource,
                          file_state: 'created',
                          download_filename: 'mytest.csv',
                          storage_version_id: @resource.id)
        allow(DataFile).to receive(:find_merritt_deposit_file).with(file: @upload).and_return(@upload)
        allow(DataFile).to receive(:find_merritt_deposit_file).with(file: @upload2).and_return(@upload2)
      end

      it 'returns nil if unable to retrieve range of S3 file' do
        stub_request(:head, %r{https://a-merritt-test-bucket.s3.us-west-2.amazonaws.com/+.})
          .to_return(status: 404, body: '', headers: {})
        stub_request(:get, %r{https://a-merritt-test-bucket.s3.us-west-2.amazonaws.com/+.})
          .to_return(status: 404, body: '', headers: {})

        expect(@upload2.text_preview).to be_nil
      end

      it 'returns content if successful request for http URL' do
        stub_request(:head, %r{https://a-merritt-test-bucket.s3.us-west-2.amazonaws.com/+.})
          .to_return(status: 200, body: "This,is,my,great,csv\n0,1,2,3,4", headers: {})
        stub_request(:get, %r{https://a-merritt-test-bucket.s3.us-west-2.amazonaws.com/+.})
          .to_return(status: 200, body: "This,is,my,great,csv\n0,1,2,3,4", headers: {})
        allow_any_instance_of(Stash::Aws::S3).to receive(:exists?).and_return(true)

        expect(@upload2.text_preview).to eql("This,is,my,great,csv\n0,1,2,3,4")
      end
    end

    describe '#file_content' do
      before(:each) do
        @upload2 = create(:data_file,
                          resource: @resource,
                          file_state: 'created',
                          download_filename: 'README.md')
        allow(DataFile).to receive(:find_merritt_deposit_file).with(file: @upload).and_return(@upload)
        allow(DataFile).to receive(:find_merritt_deposit_file).with(file: @upload2).and_return(@upload2)
      end
      it 'returns nil if unable to retrieve range of S3 file' do
        stub_request(:get, %r{https://a-test-bucket.s3.us-west-2.amazonaws.com/+.})
          .to_return(status: 404, body: '', headers: {})

        expect(@upload2.file_content).to be_nil
      end

      it 'returns content if successful request for http URL' do
        stub_request(:get, %r{https://a-test-bucket.s3.us-west-2.amazonaws.com/+.})
          .to_return(status: 200, body: '### This is a test README title!', headers: {})

        stub_request(:get, %r{https://a-test-bucket.s3.us-west-2.amazonaws.com/.+})
          .to_return(status: 200, body: '### This is a test README title!', headers: {})

        expect(@upload2.file_content).to eql('### This is a test README title!')
      end
    end

    describe :populate_container_files_from_last do
      it 'copies the files from the last version of the resource' do
        df1 = create(:data_file, download_filename: 'fromulent.zip', file_state: 'created', resource_id: @resource.id)
        fromulent_contain1 = create(:container_file, data_file: df1)

        resource2 = create(:resource, user: @user, tenant_id: 'ucop', identifier: @identifier)
        df2 = create(:data_file, download_filename: 'fromulent.zip', file_state: 'copied', resource_id: resource2.id)
        df2.populate_container_files_from_last

        df2.reload

        cf = df2.container_files.first
        expect(cf.path).to eql(fromulent_contain1.path)
        expect(cf.mime_type).to eql(fromulent_contain1.mime_type)
        expect(cf.size).to eql(fromulent_contain1.size)
      end

      it "ignores copying if this isn't a container file type" do
        df1 = create(:data_file, download_filename: 'fromulent.blog', file_state: 'created', resource_id: @resource.id)
        create(:container_file, data_file: df1)

        resource2 = create(:resource, user: @user, tenant_id: 'ucop', identifier: @identifier)
        df2 = create(:data_file, download_filename: 'fromulent.blog', file_state: 'copied', resource_id: resource2.id)
        df2.populate_container_files_from_last

        df2.reload

        expect(df2.container_files.count).to eq(0)
      end

      it 'ignores copying if this was a deleted file type' do
        df1 = create(:data_file, download_filename: 'fromulent.zip', file_state: 'deleted', resource_id: @resource.id)
        create(:container_file, data_file: df1)

        resource2 = create(:resource, user: @user, tenant_id: 'ucop', identifier: @identifier)
        df2 = create(:data_file, download_filename: 'fromulent.zip', file_state: 'created', resource_id: resource2.id)
        df2.populate_container_files_from_last

        df2.reload

        expect(df2.container_files.count).to eq(0)
      end
    end

    describe :trigger_frictionless do
      it 'calls client.invoke for an AWS lambda function and returns a 202' do
        allow(StashEngine::ApiToken).to receive(:token).and_return('123456789ABCDEF')
        expect_any_instance_of(Aws::Lambda::Client).to receive(:invoke).and_return({ status_code: 202 }.to_ostruct)
        expect(@upload.trigger_frictionless[:triggered]).to eql(true)
      end
    end

    describe :trigger_sensitive_data_scan do
      it 'calls client.invoke for an AWS lambda function and returns a 202' do
        allow(StashEngine::ApiToken).to receive(:token).and_return('123456789ABCDEF')
        expect_any_instance_of(Aws::Lambda::Client).to receive(:invoke).and_return({ status_code: 202 }.to_ostruct)
        expect(@upload.trigger_sensitive_data_scan[:triggered]).to eql(true)
      end
    end

    describe :trigger_excel_to_csv do
      it 'calls client.invoke for an AWS lambda function and returns a 202' do
        allow(StashEngine::ApiToken).to receive(:token).and_return('123456789ABCDEF')
        expect_any_instance_of(Aws::Lambda::Client).to receive(:invoke).and_return({ status_code: 202 }.to_ostruct)
        expect(@upload.trigger_excel_to_csv[:triggered]).to eql(true)
        proc_result = @resource.processor_results.first
        expect(proc_result.resource_id).to eq(@resource.id)
        expect(proc_result.processing_type).to eq('excel_to_csv')
        expect(proc_result.completion_state).to eq('not_started')
      end
    end

    # finds the last instance of the file from possibly multiple versions for forward delta deduplication
    describe :original_deposit_file do
      it 'returns the current file if only one version' do
        @resource.current_resource_state.update(resource_state: 'submitted')
        expect(@upload.original_deposit_file).to eq(@upload)
      end

      it 'returns the first file from a series of versions that were not changed' do
        @resource.current_resource_state.update(resource_state: 'submitted')
        Timecop.travel(Time.now.utc - 1.hour)
        @resource2 = create(:resource, user: @user, tenant_id: 'ucop', identifier: @identifier)
        @resource2.current_resource_state.update(resource_state: 'submitted')
        @file2 = create(:data_file, resource: @resource2, file_state: 'copied', download_filename: 'foo.bar',
                                    upload_file_name: @upload.upload_file_name)
        Timecop.return
        @resource3 = create(:resource, user: @user, tenant_id: 'ucop', identifier: @identifier)
        @resource3.current_resource_state.update(resource_state: 'submitted')
        @file3 = create(:data_file, resource: @resource3, file_state: 'copied', download_filename: 'foo.bar',
                                    upload_file_name: @upload.upload_file_name)

        expect(@file3.original_deposit_file).to eq(@upload)
      end

      it 'returns last uploaded submission, not the original submission' do
        @resource.current_resource_state.update(resource_state: 'submitted')
        Timecop.travel(Time.now.utc - 2.hours)
        @resource2 = create(:resource, user: @user, tenant_id: 'ucop', identifier: @identifier)
        @resource2.current_resource_state.update(resource_state: 'submitted')
        @file2 = create(:data_file, resource: @resource2, file_state: 'deleted', download_filename: 'foo.bar',
                                    upload_file_name: @upload.upload_file_name)
        Timecop.travel(Time.now.utc + 1.hour)
        @resource3 = create(:resource, user: @user, tenant_id: 'ucop', identifier: @identifier)
        @resource3.current_resource_state.update(resource_state: 'submitted')
        @file3 = create(:data_file, resource: @resource3, file_state: 'created', download_filename: 'foo.bar')
        Timecop.return
        @resource4 = create(:resource, user: @user, tenant_id: 'ucop', identifier: @identifier)
        @resource4.current_resource_state.update(resource_state: 'submitted')
        @file4 = create(:data_file, resource: @resource4, file_state: 'copied', download_filename: 'foo.bar',
                                    upload_file_name: @file3.upload_file_name)

        expect(@file4.original_deposit_file).to eq(@file3)
      end

      it 'returns last submission if submitted last even if other stuff before' do
        @resource.current_resource_state.update(resource_state: 'submitted')
        Timecop.travel(Time.now.utc - 2.hours)
        @resource2 = create(:resource, user: @user, tenant_id: 'ucop', identifier: @identifier)
        @resource2.current_resource_state.update(resource_state: 'submitted')
        @file2 = create(:data_file, resource: @resource2, file_state: 'copied', download_filename: 'foo.bar',
                                    upload_file_name: @upload.upload_file_name)
        Timecop.travel(Time.now.utc + 1.hour)
        @resource3 = create(:resource, user: @user, tenant_id: 'ucop', identifier: @identifier)
        @resource3.current_resource_state.update(resource_state: 'submitted')
        @file3 = create(:data_file, resource: @resource3, file_state: 'copied', download_filename: 'foo.bar',
                                    upload_file_name: @upload.upload_file_name)
        Timecop.return
        @resource4 = create(:resource, user: @user, tenant_id: 'ucop', identifier: @identifier)
        @resource4.current_resource_state.update(resource_state: 'submitted')
        @file4 = create(:data_file, resource: @resource4, file_state: 'created', download_filename: 'foo.bar')

        expect(@file4.original_deposit_file).to eq(@file4)
      end
    end

    # find where merritt actually deposited this file, since it may differ if identical file with same name has been uploaded
    # more than once
    describe :find_merritt_deposit_file do

      let(:instance) { instance_double(Stash::Aws::S3) }
      let(:double_class) do
        class_double(Stash::Aws::S3).as_stubbed_const
      end

      before(:each) do
        # make Stash::Aws::S3 an rspec "spy", so we can test how it was called
        allow(Stash::Aws::S3).to receive(:new).and_return(instance)
        # file v1 one exists in s3 and v2 doesn't
        allow(instance).to receive(:exists?) { |args|
          args[:s3_key].include?('1|producer')
        }
      end

      it 'returns myself if the file exists on S3' do
        @resource.current_resource_state.update(resource_state: 'submitted')

        expect(DataFile.find_merritt_deposit_file(file: @upload)).to eq(@upload)
      end

      it 'returns the initial file if the second file is a copy of the first, even if both are created' do
        @resource.current_resource_state.update(resource_state: 'submitted')

        @resource2 = create(:resource, user: @user, tenant_id: 'ucop', identifier: @identifier)
        @resource2.current_resource_state.update(resource_state: 'submitted')
        @file2 = create(:data_file, resource: @resource2, file_state: 'created', download_filename: 'foo.bar',
                                    upload_file_name: @upload.upload_file_name, upload_file_size: @upload.upload_file_size)

        expect(DataFile.find_merritt_deposit_file(file: @file2)).to eq(@upload)
      end
    end

    # finds a path to a merritt version of the file independent of how many versions we have in our database
    # Usually these are things manually fixed in Merritt where Dryad only has v1 and Merritt is up to v3 or similar.
    # often these are Dash legacy datasets that were migrated to one Dryad collection.
    describe :find_merritt_deposit_path do

      let(:instance) { instance_double(Stash::Aws::S3) }
      let(:double_class) do
        class_double(Stash::Aws::S3).as_stubbed_const
      end

      before(:each) do
        # make Stash::Aws::S3 an rspec "spy", so we can test how it was called
        allow(Stash::Aws::S3).to receive(:new).and_return(instance)
        # file v1 one exists in s3 and v2 doesn't
        allow(instance).to receive(:exists?) { |args|
          args[:s3_key].include?('1|producer')
        }
      end

      # this method is used as a fallback after it has tried better and more specific methods first
      it 'walks back from merritt 3 version 1 to try and find an earlier version in S3 with the file' do
        @upload.resource.stash_version.update(merritt_version: 3)
        @upload.reload

        expect(@upload.s3_permanent_path).to include('1|producer')
      end
    end

    describe :s3_permanent_path do
      before(:each) do
        allow(DataFile).to receive(:find_merritt_deposit_file).with(file: @upload).and_return(@upload)
      end

      it 'generates the merritt URL in S3 bucket' do
        allow_any_instance_of(Stash::Aws::S3).to receive(:exists?).and_return(true)

        @resource.current_resource_state.update(resource_state: 'submitted')
        expect(@upload.s3_permanent_path).to include("-#{@resource.id}/data/#{@upload.upload_file_name}")
      end
    end

    describe :s3_permanent_presigned_url do
      before(:each) do
        expect_any_instance_of(Stash::Aws::S3).to receive(:presigned_download_url).with(s3_key: s3_permanent_path)
        @resource.current_resource_state.update(resource_state: 'submitted')
        @upload.s3_permanent_presigned_url
      end
    end

  end
end
