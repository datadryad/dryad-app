describe StashEngine::ResourceMailer, type: :mailer do

  let(:identifier) { create(:identifier) }
  let(:resource) { create(:resource, identifier: identifier) }
  let(:user) { create(:user) }
  let(:author) { resource.authors.first }

  before do
    resource&.reload
    identifier.reload
  end

  describe '#in_progress_delete_notification' do
    let(:mail) { described_class.in_progress_delete_notification(resource).deliver_now }

    it 'sends an error report email' do
      expect(mail.to).to eq([author.author_email])
      expect(mail.subject).to eq("[test] REMINDER: Dryad submission \"#{resource.title}\"")
      expect(mail.body.to_s).to include("The Dryad dataset submission you’ve initiated titled, “#{resource.title}” with the")
      expect(mail.body.to_s).to include("DOI “#{identifier.identifier}”, is currently \"In Progress\".")
    end

    include_examples 'does not send email for missing resource or user email'
  end

  describe '#peer_review_delete_notification' do
    let(:mail) { described_class.peer_review_delete_notification(resource).deliver_now }

    it 'sends an error report email' do
      expect(mail.to).to eq([author.author_email])
      expect(mail.subject).to eq("[test] REMINDER: Dryad submission \"#{resource.title}\"")
      expect(mail.body.to_s).to include('As a reminder, your Dryad dataset is currently in "Private for Peer Review" (PPR) status')
      expect(mail.body.to_s).to include(identifier.to_s)
    end

    include_examples 'does not send email for missing resource or user email'
  end

  describe '#action_required_delete_notification' do
    let(:mail) { described_class.action_required_delete_notification(resource).deliver_now }

    it 'sends an error report email' do
      expect(mail.to).to eq([author.author_email])
      expect(mail.subject).to eq("[test] REMINDER: Dryad submission \"#{resource.title}\"")
      expect(mail.body.to_s).to include('Previously, we requested modifications to your Dryad dataset submission. As a reminder, these')
      expect(mail.body.to_s).to include('changes must be addressed before we can publish your dataset:')
      expect(mail.body.to_s).to include(identifier.identifier.to_s)
    end

    include_examples 'does not send email for missing resource or user email'
  end

  describe '#send_set_to_withdrawn_notification' do
    let(:mail) { described_class.send_set_to_withdrawn_notification(resource).deliver_now }

    it 'sends an error report email' do
      expect(mail.to).to eq([author.author_email])
      expect(mail.subject).to eq("[test] NOTIFICATION: Dryad submission set to withdrawn \"#{resource.title}\"")
      expect(mail.body.to_s).to include('Your data submission has been automatically withdrawn from the Dryad platform')
      expect(mail.body.to_s).to include('due to inactivity for more than one year. Your data will be permanently')
      expect(mail.body.to_s).to include('deleted after one year with further inactivity')
      expect(mail.body.to_s).to include(identifier.to_s)
    end

    include_examples 'does not send email for missing resource or user email'
  end

  describe '#send_final_withdrawn_notification' do
    let(:mail) { described_class.send_final_withdrawn_notification(resource).deliver_now }

    it 'sends an error report email' do
      expect(mail.to).to eq([author.author_email])
      expect(mail.subject).to eq("[test] FINAL NOTIFICATION: Dryad submission will be deleted \"#{resource.title}\"")
      expect(mail.body.to_s).to include('Your data submission that was withdrawn from the Dryad platform will be permanently deleted in three months')
      expect(mail.body.to_s).to include(identifier.to_s)
    end

    include_examples 'does not send email for missing resource or user email'
  end

  describe '#delete_notification' do
    let(:mail) { described_class.delete_notification(resource).deliver_now }

    it 'sends an error report email' do
      expect(mail.to).to eq([author.author_email])
      expect(mail.subject).to eq("[test] DELETE NOTIFICATION: Dryad submission was deleted \"#{resource.title}\"")
      expect(mail.body.to_s).to include(
        'Your data submission has been automatically deleted from the Dryad platform after being “In progress” for one year with no action'
      )
      expect(mail.body.to_s).to include(identifier.to_s)
    end

    include_examples 'does not send email for missing resource or user email'
  end
end
