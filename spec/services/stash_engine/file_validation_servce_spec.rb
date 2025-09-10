module StashEngine
  describe FileValidationService do
    include Mocks::Aws
    include Mocks::Salesforce

    let(:identifier) { create(:identifier) }
    let(:resource) { create(:resource, identifier: identifier, created_at: 1.minute.ago) }
    let(:resource2) { create(:resource, identifier: identifier) }
    let(:file) do
      create(:data_file, resource: resource, digest_type: 'md5', digest: '123456asfg', upload_file_size: 10, file_state: 'created',
                         original_filename: 'same_name.txt')
    end
    let(:sums) { double('Checksums', get_checksum: '123456asfg', input_size: 10) }

    subject(:service) { described_class.new(file: file) }

    before do
      mock_aws!
      mock_salesforce!

      allow(Stash::Checksums).to receive(:get_checksums).and_return(sums)
    end

    describe '#initialize' do
      it 'sets params' do
        instance = described_class.new(file: file)
        expect(instance.file).to eq(file)
      end
    end

    describe '#validate_file' do
      before do
        allow(Stash::Checksums).to receive(:get_checksums).and_return(sums)
      end

      it 'marks file as validated when checksum and size match' do
        service.validate_file

        expect(file.reload.validated_at).to be_within(1).of(Time.now.utc)
      end

      it 'sends error mail when checksum mismatch' do
        allow(sums).to receive(:get_checksum).and_return('wrong')
        allow(StashEngine::UserMailer).to receive_message_chain(:file_validation_error, :deliver_now)
        service.validate_file

        expect(StashEngine::UserMailer).to have_received(:file_validation_error).with(file)
      end

      it 'sends error mail when checksum mismatch' do
        allow(sums).to receive(:input_size).and_return(11)
        allow(StashEngine::UserMailer).to receive_message_chain(:file_validation_error, :deliver_now)
        service.validate_file

        expect(StashEngine::UserMailer).to have_received(:file_validation_error).with(file)
      end
    end

    describe '#recreate_digests' do
      let(:sums) { double('Checksums', get_checksum: 'other', input_size: 10) }

      it 'updated file and marks it as validated when size patch' do
        expect do
          service.recreate_digests
        end.to change(file, :digest).to('other')
          .and change(file, :digest_type).to('sha-256')
          .and change(file, :validated_at)
        expect(file.reload.validated_at).to be_within(1).of(Time.now.utc)
      end

      context 'when file size does not match' do
        let(:sums) { double('Checksums', get_checksum: 'other', input_size: 11) }

        it 'sends error mail when checksum mismatch' do
          allow(StashEngine::UserMailer).to receive_message_chain(:file_validation_error, :deliver_now)

          expect { service.recreate_digests }.not_to(change { file })
          expect(StashEngine::UserMailer).to have_received(:file_validation_error).with(file)
        end
      end
    end

    describe '#copy_digests' do
      let!(:original_file) do
        create(:data_file, resource: resource, digest_type: 'md5', digest: '123456asfg', upload_file_size: 10, validated_at: 1.minute.ago,
                           file_state: 'created', upload_file_name: 'same_name.txt')
      end
      let(:file) do
        create(:data_file, resource: resource2, digest_type: nil, digest: nil, upload_file_size: 10, validated_at: nil, file_state: 'copied',
                           upload_file_name: 'same_name.txt')
      end

      before do
        resource.current_state = 'submitted'
      end

      it 'updated file and marks it as validated when size patch' do
        expect do
          service.copy_digests
        end.to change(file, :digest).to('123456asfg')
          .and change(file, :digest_type).to('md5')
          .and change(file, :validated_at)
      end

      context 'when file digests match' do
        let(:file) do
          create(:data_file, resource: resource2, digest_type: nil, digest: '123456asfg',
                             upload_file_size: 10, validated_at: nil, file_state: 'copied',
                             upload_file_name: 'same_name.txt')
        end

        it 'does not update file' do
          expect { service.recreate_digests }.not_to(change { file })
        end
      end
    end
  end
end
