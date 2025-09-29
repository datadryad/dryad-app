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
end
