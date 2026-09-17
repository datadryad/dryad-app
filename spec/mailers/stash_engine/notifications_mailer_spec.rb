RSpec.describe StashEngine::NotificationsMailer, type: :mailer do

  let(:health_status) do
    {
      database: { status: :connected },
      aws: { status: :connected },
      solr: { status: 'not connected', error: 'Some error message' }
    }
  end

  describe '#health_status_change' do
    let(:mail) { described_class.health_status_change(:service_unavailable, health_status).deliver_now }

    it 'sends to devs@datadryad.org' do
      expect(mail.to).to eq(['devs@datadryad.org'])
    end

    it 'sets the correct subject' do
      expect(mail.subject).to eq('[test] Health check status changed - service_unavailable')
    end

    it 'assigns variables to the view' do
      expect(mail.body.encoded).to match('SERVICE_UNAVAILABLE')
    end
  end

  describe '#submission_queue_too_large' do
    let(:mail) { described_class.submission_queue_too_large(42).deliver_now }

    it 'sends to devs@datadryad.org' do
      expect(mail.to).to eq(['devs@datadryad.org'])
    end

    it 'sets the correct subject' do
      expect(mail.subject).to include('Submission queue too large')
    end

    it 'includes count in body' do
      expect(mail.body.encoded).to match('42')
    end
  end

  describe '#certbot_expiration' do
    let(:mail) { described_class.certbot_expiration(7).deliver_now }

    it 'sends to devs@datadryad.org' do
      expect(mail.to).to eq(['devs@datadryad.org'])
    end

    it 'sets the correct subject' do
      expect(mail.subject).to include('SSL Cert expires in 7 days')
    end

    it 'includes expiration days in body' do
      expect(mail.body.encoded).to match('7')
    end
  end

  describe '#error_report' do
    let(:error) { ArgumentError.new }
    let(:mail) { described_class.error_report(resource, error).deliver_now }

    it 'sends an error report email' do
      expect(mail.subject).to start_with('[test] Submitting dataset')
      expect(mail.subject).to end_with('failed')
      expect(mail.body.to_s).to include('The error details are below.')
    end
  end

  describe '#general_error' do
    let(:error) { ArgumentError.new }
    let(:mail) { described_class.general_error(resource, error).deliver_now }

    it 'sends an error report email' do
      expect(mail.subject).to eq("[test] General error \"#{resource.title}\" (#{identifier})")
      expect(mail.body.to_s).to include('ArgumentError')
      expect(mail.body.to_s).to include("doi: #{identifier.identifier}")
    end

    context 'when resource is not present' do
      let(:resource) { nil }

      include_examples 'should not send an email'
    end
  end

  describe '#file_validation_error' do
    let(:file) { create(:data_file, resource: resource) }
    let(:mail) { described_class.file_validation_error(file).deliver_now }

    before { mock_aws! }

    it 'sends an error report email' do
      expect(mail.subject).to eq('[test] File checksum validation error')
      expect(mail.body.to_s).to include('File cannot be validated; possible corruption!')
      expect(mail.body.to_s).to include("filename: #{file.download_filename}")
    end

    context 'when file is not present' do
      let(:file) { nil }

      include_examples 'should not send an email'
    end
  end

  describe '#feedback_signup' do
    let(:mail) { described_class.feedback_signup('Some message').deliver_now }

    it 'sends an error report email' do
      expect(mail.to).to eq(APP_CONFIG['developer_email'])
      expect(mail.subject).to eq('[test] User testing signup')
      expect(mail.body.to_s).to include('A user has signed up to participate in testing')
    end
  end

  describe '#dependency_offline' do
    let(:dependency) { create(:external_dependency) }
    let(:mail) { described_class.dependency_offline(dependency, 'Some message').deliver_now }

    it 'sends an error report email' do
      expect(mail.to).to eq(APP_CONFIG['developer_email'])
      expect(mail.subject).to eq("[test] dependency offline: #{dependency.name}")
      expect(mail.body.to_s).to include('Its error message is: Some message')
    end

    context 'when dependency is not present' do
      let(:dependency) { nil }

      include_examples 'should not send an email'
    end
  end

  describe '#zenodo_error' do
    let(:zenodo_copy) do
      create(:zenodo_copy, identifier: identifier, resource: resource, state: 'error', error_info: 'Something bad just happened',
                           software_doi: '10.2837/zenodo.bad_test', conceptrecid: '123345')
    end
    let(:mail) { described_class.zenodo_error(zenodo_copy).deliver_now }

    it 'send a zenodo error report' do
      expect(mail.subject).to start_with('[test] Failed to update Zenodo for')
      expect(mail.subject).to end_with('for event type data')
      expect(mail.body.to_s).to include('Something bad just happened')
    end
  end

  describe '#voided_invoices' do
    let(:list) { [identifier] }
    let(:mail) { described_class.voided_invoices(list).deliver_now }

    it 'sends an error report email' do
      expect(mail.to).to eq(APP_CONFIG['developer_email'])
      expect(mail.subject).to eq('[test] Voided invoices need to be updated')
      expect(mail.body.to_s).to include('There are invoices that have been voided in Stripe, but they are still active in Dryad.')
      expect(mail.body.to_s).to include(identifier.identifier.to_s)
    end

    context 'when dependency is not present' do
      let(:list) { [] }

      include_examples 'should not send an email'
    end
  end
end
