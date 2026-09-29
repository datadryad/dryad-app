describe StashEngine::JournalMailer, type: :mailer do
  let(:journal) { create(:journal, notify_contacts: ['notify@email.com'], review_contacts: ['review@email.com']) }
  let!(:journal_issn) { create(:journal_issn, journal: journal) }
  let(:identifier) { create(:identifier) }
  let(:resource) { create(:resource, identifier: identifier, journal_issn: journal.issns.first) }
  let(:user) { create(:user) }
  let(:author) { resource.authors.first }

  before do
    resource&.reload
    identifier.reload
  end

  describe '#journal_published_notice' do
    let(:status) { 'published' }
    let(:mail) { described_class.journal_published_notice(resource, status).deliver_now }

    before do
      stub_const('APP_CONFIG', { 'send_journal_published_notices' => true })
    end

    context 'when status is "published"' do
      it 'sends an invitation' do
        expect(mail.to).to eq(['notify@email.com'])
        expect(mail.subject).to eq("[test] Dryad Submission: \"#{resource.title}\"")
        expect(mail.body.to_s).to include('We are happy to confirm that this dataset has been approved for publication in Dryad')
      end
    end

    context 'when status is "embargoed"' do
      let(:status) { 'embargoed' }

      it 'sends an invitation' do
        expect(mail.to).to eq(['notify@email.com'])
        expect(mail.subject).to eq("[test] Dryad Submission: \"#{resource.title}\"")
        expect(mail.body.to_s).to include('We are happy to confirm that this dataset has been approved for publication in Dryad')
      end
    end

    context 'when status is not "published"' do
      let(:status) { 'queued' }

      include_examples 'should not send an email'
    end

    context 'when there is no contact' do
      let(:journal) { create(:journal, notify_contacts: nil) }

      include_examples 'should not send an email'
    end

    context 'when config does not allow tit' do
      before do
        stub_const('APP_CONFIG', { 'send_journal_published_notices' => false })
      end

      include_examples 'should not send an email'
    end
  end

  describe '#journal_review_notice' do
    let(:status) { 'peer_review' }
    let(:mail) { described_class.journal_review_notice(resource, status).deliver_now }

    before do
      stub_const('APP_CONFIG', { 'send_journal_published_notices' => true })
    end

    context 'when status is "peer_review"' do
      it 'sends an invitation' do
        expect(mail.to).to eq(['review@email.com'])
        expect(mail.subject).to eq("[test] Dryad Submission: \"#{resource.title}\"")
        expect(mail.body.to_s).to include('This dataset has been successfully submitted to Dryad')
      end
    end

    context 'when status is not "peer_review"' do
      let(:status) { 'queued' }

      include_examples 'should not send an email'
    end

    context 'when there is no contact' do
      let(:journal) { create(:journal, review_contacts: nil) }

      include_examples 'should not send an email'
    end

    context 'when config does not allow tit' do
      before do
        stub_const('APP_CONFIG', { 'send_journal_published_notices' => false })
      end

      include_examples 'should not send an email'
    end
  end

  describe '#user_journal_withdrawn' do
    let(:status) { 'withdrawn' }
    let(:mail) { described_class.user_journal_withdrawn(resource, status).deliver_now }

    it 'sends an invitation' do
      expect(mail.subject).to eq("[test] Dryad Submission \"#{resource.title}\"")
      expect(mail.body.to_s).to include('we have withdrawn your related Dryad data submission')
    end

    context 'when status is not "withdrawn"' do
      let(:status) { 'published' }

      include_examples 'should not send an email'
    end

    context 'the email was already sent' do
      before do
        create(:curation_activity, resource: resource, note: 'remove_abandoned_datasets CRON - removing data files from abandoned dataset')
      end

      include_examples 'should not send an email'
    end
  end
end
