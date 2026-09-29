describe StashEngine::ResourceMailer, type: :mailer do
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

  describe 'curation #status_change' do
    let(:mail) { described_class.status_change(resource, status).deliver_now }
    before do
      allow(resource).to receive(:current_curation_status).and_return(status)
      allow(resource).to receive(:publication_date).and_return(Time.now.utc.to_date)
    end

    StashEngine::CurationActivity.statuses.each_key do |status|
      context "when status is '#{status}'" do
        let(:status) { status }

        if %w[peer_review queued published embargoed withdrawn].include?(status)
          it 'should send an email' do
            case status
            when 'peer_review'
              expect(mail.body.to_s).to include(identifier.shares.first.sharing_link)
              expect(mail.body.to_s).to include('your submission will not enter our curation process for review and publication')
            when 'queued'
              expect(mail.body.to_s).to include('Thank you for your submission to Dryad')
            when 'published'
              expect(mail.body.to_s).to include('approved for publication')
              expect(mail.body.to_s).to include(identifier.identifier.to_s)
            when 'embargoed'
              expect(mail.subject).to eq("[test] Dryad Submission \"#{resource.title}\"")
              expect(mail.body.to_s).to include('will be embargoed until')
            when 'withdrawn'
              expect(mail.body.to_s).to include('Your data submission has been withdrawn from the Dryad platform')
              expect(mail.body.to_s).to include(identifier.identifier.to_s)
            end
          end
        else
          include_examples 'should not send an email'
        end
      end
    end

    context 'title with HTML elements' do
      let(:status) { 'queued' }

      it 'does not include HTML elements in the email subject' do
        allow(resource).to receive(:title).and_return('A dataset title that contains <em>italics</em> and <sup>stuff</sup>')

        expect(resource.title.strip_tags).to eq('A dataset title that contains italics and stuff')
        expect(mail.subject).to eq("[test] Dryad Submission \"#{resource.title.strip_tags}\"")
      end
    end

    context 'when journal has peer_review_custom_text' do
      let(:status) { 'peer_review' }
      let(:journal) { create(:journal, peer_review_custom_text: 'This is a custom peer review message') }

      it 'contains the custom text' do
        expect(mail.subject).to eq("[test] Dryad Submission \"#{resource.title}\"")

        expect(mail.body.to_s).to include(identifier.shares.first.sharing_link)
        expect(mail.body.to_s).to include('your submission will not enter our curation process for review and publication')
        expect(mail.body.to_s).to include('This is a custom peer review message')
      end
    end

    describe 'publication email' do
      let(:fake_resource) { create(:resource) }
      let(:test_doi) { "#{rand.to_s[2..6]}/zenodo.#{rand.to_s[2..11]}" }
      let(:test_doi2) { "#{rand.to_s[2..6]}/zenodo.#{rand.to_s[2..11]}" }
      let(:status) { 'published' }

      before(:each) do
        create(:related_identifier, related_identifier: "https://doi.org/#{test_doi}",
                                    resource_id: fake_resource.id, added_by: 'zenodo', work_type: 'software')
        create(:related_identifier, related_identifier: "https://doi.org/#{test_doi2}",
                                    resource_id: fake_resource.id, added_by: 'zenodo', work_type: 'supplemental_information')
        allow(resource).to receive(:related_identifiers).and_return(fake_resource.related_identifiers)
      end

      it 'should show info about zenodo software doi and zenodo supplemental info when present' do
        expect(mail.subject).to eq("[test] Dryad Submission \"#{resource.title}\"")
        expect(mail.body.to_s).to include('Your related software files are now published and publicly available on Zenodo')
        expect(mail.body.to_s).to include('Your supplemental information is now published and publicly available on Zenodo')
        expect(mail.body.to_s).to include(test_doi)
        expect(mail.body.to_s).to include(test_doi2)
      end
    end

    describe 'embargoed status changes' do
      let(:status) { 'embargoed' }

      before do
        allow(resource.identifier).to receive(:embargoed_until_article_appears?).and_return(true)
      end

      it "should send an modified email when embargoed_until_article_appears'" do
        expect(mail.subject).to eq("[test] Dryad Submission \"#{resource.title}\"")
        expect(mail.body.to_s).to include('until the associated article appears')
      end
    end
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
      expect(mail.body.to_s).to include('Previously, via a message sent to your Dryad user account email address, we requested modifications to your')
      expect(mail.body.to_s).to include('Dryad dataset submission. As a reminder, these changes must be addressed before we can publish your dataset')
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

  describe '#in_progress_reminder' do
    let(:mail) { described_class.in_progress_reminder(resource).deliver_now }

    it 'sends an error report email' do
      expect(mail.to).to eq([author.author_email])
      expect(mail.subject).to eq("[test] REMINDER: Dryad Submission \"#{resource.title}\"")
      expect(mail.body.to_s).to include("The Dryad dataset submission you’ve initiated titled, “#{resource.title}” with the")
      expect(mail.body.to_s).to include("DOI “#{identifier.identifier}”, is currently \"In Progress\".")
    end

    include_examples 'does not send email for missing resource or user email'
  end

  describe '#peer_review_payment_needed' do
    let(:mail) { described_class.peer_review_payment_needed(resource).deliver_now }

    it 'sends an error report email' do
      expect(mail.to).to eq([author.author_email])
      expect(mail.subject).to eq("[test] Dryad Submission \"#{resource.title}\"")
      expect(mail.body.to_s).to include('A published or accepted article has been linked to your Dryad data submission')
      expect(mail.body.to_s).to include(
        "Payment of the <a href=\"#{Rails.application.routes.url_helpers.costs_url}\">Data Publishing Charge</a> is required"
      )
      expect(mail.body.to_s).to include("DOI: #{identifier.identifier}")
    end

    include_examples 'does not send email for missing resource or user email'
  end

  describe '#peer_review_pub_linked' do
    let(:mail) { described_class.peer_review_pub_linked(resource).deliver_now }

    it 'sends an error report email' do
      expect(mail.to).to eq([author.author_email])
      expect(mail.subject).to eq("[test] Dryad Submission \"#{resource.title}\"")
      expect(mail.body.to_s).to include('A published or accepted article has been linked to your Dryad data submission')
      expect(mail.body.to_s).to include('Therefore your submission will be automatically released for curation and publication.')
      expect(mail.body.to_s).to include("DOI: #{identifier.identifier}")
    end

    include_examples 'does not send email for missing resource or user email'
  end

  describe '#doi_invitation' do
    let(:mail) { described_class.doi_invitation(resource).deliver_now }

    it 'sends an error report email' do
      expect(mail.to).to eq([author.author_email])
      expect(mail.subject).to eq('[test] Connect your data to your research on Dryad!')
      expect(mail.body.to_s).to include("Published dataset: #{resource.title}")
    end

    include_examples 'does not send email for missing resource or user email'
  end

  describe '#related_work_updated' do
    let(:mail) { described_class.related_work_updated(resource).deliver_now }

    it 'sends an error report email' do
      expect(mail.to).to eq([author.author_email])
      expect(mail.subject).to eq("[test] Related work updated for \"#{resource.title}\"")
      expect(mail.body.to_s).to include('We have received an update to a related work for your dataset.')
      expect(mail.body.to_s).to include(identifier.identifier.to_s)
    end

    include_examples 'does not send email for missing resource or user email'
  end

  describe '#chase_action_required1' do
    let(:mail) { described_class.chase_action_required1(resource).deliver_now }

    it 'sends an error report email' do
      expect(mail.to).to eq([author.author_email])
      expect(mail.subject).to eq("[test] Action required: Dryad data submission (#{resource.identifier})")
      expect(mail.body.to_s).to include('Previously, via a message sent to your Dryad user account email address, we requested modifications to your')
      expect(mail.body.to_s).to include('Dryad dataset submission. As a reminder, these changes must be addressed before we can publish your dataset')
      expect(mail.body.to_s).to include('changes must be addressed before we can publish your dataset:')
      expect(mail.body.to_s).to include(identifier.identifier)
      expect(mail.body.to_s).to include("Title: \"#{resource.title}\"")
    end

    include_examples 'does not send email for missing resource or user email'
  end
end
