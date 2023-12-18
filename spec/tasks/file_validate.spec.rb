describe 'checksums:validate_files', type: :task do

  before(:each) do
    @resource = create(:resource)
    @file = create(:data_file, resource: @resource, file_state: 'created', digest_type: 'sha-256',
                               digest: '4600db3135dcfd11dfe0b7c35a382329218306b40adb5a7a5257d0f596c3a0ad',
                               upload_file_name: 'valid.csv', upload_file_size: 501)
    url = 'https://a-merritt-test-bucket.s3.us-west-2.amazonaws.com/ark:/99999/fkv3zfjd28%7C1%7Cproducer/valid.csv'
    allow_any_instance_of(StashEngine::DataFile).to receive(:s3_permanent_presigned_url).and_return(url)
    stub_request(:any, %r{https://a-merritt-test-bucket.s3.us-west-2.amazonaws.com/ark+.}).to_return(
      body: File.open("#{Rails.root}/spec/fixtures/stash_engine/valid.csv"), status: 200
    )
  end

  it 'updates validated_at when file is valid' do
    Rake::Task['checksums:validate_files'].invoke
    @file.reload
    expect(@file.validated_at.to_date).to eq(Date.today)
  end

  it 'only checks original files' do
    @file.file_state = 'copied'
    @file.save
    @file.reload
    Rake::Task['checksums:validate_files'].invoke
    @file.reload
    expect(@file.validated_at).to eq(nil)
  end

end
