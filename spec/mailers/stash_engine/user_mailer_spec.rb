describe StashEngine::UserMailer, type: :mailer do
  include Mocks::Aws

  let(:tenant) { create(:tenant_email, authentication: { email_domain: 'domain.com' }.to_json) }
  let(:journal) { create(:journal, notify_contacts: ['notify@email.com'], review_contacts: ['review@email.com']) }
  let!(:journal_issn) { create(:journal_issn, journal: journal) }
  let(:identifier) { create(:identifier) }
  let(:resource) { create(:resource, identifier: identifier, journal_issn: journal.issns.first) }
  let(:user) { create(:user) }
  let(:author) { resource.authors.first }
  let(:request_host) { 'stash.example.org' }

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
        expect(mail.body.to_s).to include('Congratulations! This dataset has been approved for publication in Dryad')
      end
    end

    context 'when status is "embargoed"' do
      let(:status) { 'embargoed' }

      it 'sends an invitation' do
        expect(mail.to).to eq(['notify@email.com'])
        expect(mail.subject).to eq("[test] Dryad Submission: \"#{resource.title}\"")
        expect(mail.body.to_s).to include('Congratulations! This dataset has been approved for publication in Dryad')
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

  describe '#check_email' do
    let!(:token) { create(:email_token, user: user) }
    let(:mail) { described_class.check_email(token).deliver_now }

    it 'send an email' do
      expect(mail.to).to eq([user.email])
      expect(mail.subject).to eq('[test] Your Dryad account code')
      expect(mail.body.to_s).to include('Use the following code to confirm your email address with Dryad.')
    end

    context 'when user email is not set' do
      let(:user) { create(:user, email: nil) }

      include_examples 'should not send an email'
    end
  end

  describe '#check_tenant_email' do
    let!(:token) { create(:email_token, user: user, tenant: tenant) }
    let(:mail) { described_class.check_tenant_email(token).deliver_now }
    let(:user) { create(:user, email: 'email@domain.com') }

    it 'send an email' do
      expect(mail.to).to eq([user.email])
      expect(mail.subject).to eq('[test] Your Dryad account code')
      expect(mail.body.to_s).to include("Use the following code to confirm your affiliation with #{tenant.long_name}, a Dryad partner.")
    end

    context 'when user email is not set' do
      let(:user) { create(:user, email: nil) }

      include_examples 'should not send an email'
    end

    context 'when user email domain is different' do
      let(:user) { create(:user, email: 'email@domain1.com') }

      include_examples 'should not send an email'
    end

    context 'when tenant authentication domain is not set' do
      let(:tenant) { create(:tenant_email, authentication: { email_domain: '' }.to_json) }

      include_examples 'should not send an email'
    end
  end

  describe '#invite_author' do
    let(:edit_code) { create(:edit_code, author: author, role: :collaborator) }
    let(:mail) { described_class.invite_author(edit_code).deliver_now }

    it 'send an email' do
      expect(mail.to).to eq([author.author_email])
      expect(mail.subject).to eq("[test] Invitation to edit submission \"#{resource.title}\"")
      expect(mail.body.to_s).to include('You have been invited to collaborate on the Dryad data submission')
    end

    context 'when role is submitter' do
      let(:edit_code) { create(:edit_code, author: author, role: :submitter) }

      it 'send an email' do
        expect(mail.to).to eq([author.author_email])
        expect(mail.subject).to eq("[test] Invitation to edit submission \"#{resource.title}\"")
        expect(mail.body.to_s).to include('You have been invited to collaborate on the Dryad data submission')
      end
    end

    context 'when author email is not set' do
      let(:author) { create(:author, author_email: nil) }

      include_examples 'should not send an email'
    end
  end

  describe '#invite_user' do
    let(:role) { create(:role, user: user, role: :collaborator, role_object: resource) }
    let(:mail) { described_class.invite_user(user, role).deliver_now }

    it 'send an email' do
      expect(mail.to).to eq([user.email])
      expect(mail.subject).to eq("[test] Invitation to edit submission \"#{resource.title}\"")
      expect(mail.body.to_s).to include('You have been invited to collaborate on the Dryad data submission')
    end

    context 'when user email is not set' do
      let(:user) { create(:user, email: nil) }

      include_examples 'should not send an email'
    end
  end

  describe '#orcid_invitation' do
    let(:invite) { double(StashEngine::OrcidInvitation) }
    let(:mail) { described_class.orcid_invitation(invite).deliver_now }

    before do
      allow(invite).to receive(:resource).and_return(resource)
      allow(invite).to receive(:tenant).and_return(resource.tenant)
      allow(invite).to receive(:identifier).and_return(identifier.identifier)
      allow(invite).to receive(:secret).and_return('my_secret')
      allow(invite).to receive(:landing).and_return("https://#{request_host}/fake_invite")
      allow(invite).to receive(:email).and_return(user.email)
      allow(invite).to receive(:first_name).and_return(user.email)
      allow(invite).to receive(:last_name).and_return(user.email)
    end

    it 'sends an invitation' do
      expect(mail.subject).to eq("[test] Dryad Submission \"#{resource.title}\"")
      expect(mail.body.to_s).to include('we encourage you to link your ORCID iD to this publication by following the URL below')
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
      expect(mail.to).to eq(APP_CONFIG['submission_error_email'])
      expect(mail.subject).to eq('[test] User testing signup')
      expect(mail.body.to_s).to include('A user has signed up to participate in testing')
    end
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

  describe '#peer_review_reminder' do
    let(:mail) { described_class.peer_review_reminder(resource).deliver_now }

    it 'sends an error report email' do
      expect(mail.to).to eq([author.author_email])
      expect(mail.subject).to eq("[test] REMINDER: Dryad Submission \"#{resource.title}\"")
      expect(mail.body.to_s).to include('As a reminder, your Dryad dataset is currently in "Private for Peer Review" (PPR) status')
      expect(mail.body.to_s).to include("DOI: #{identifier.identifier}")
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

  describe '#dependency_offline' do
    let(:dependency) { create(:external_dependency) }
    let(:mail) { described_class.dependency_offline(dependency, 'Some message').deliver_now }

    it 'sends an error report email' do
      expect(mail.to).to eq(APP_CONFIG['submission_error_email'])
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
      expect(mail.to).to eq(APP_CONFIG['submission_error_email'])
      expect(mail.subject).to eq('[test] Voided invoices need to be updated')
      expect(mail.body.to_s).to include('There are invoices that have been voided in Stripe, but they are still active in Dryad.')
      expect(mail.body.to_s).to include(identifier.identifier.to_s)
    end

    context 'when dependency is not present' do
      let(:list) { [] }

      include_examples 'should not send an email'
    end
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
      expect(mail.body.to_s).to include('Previously, we requested modifications to your Dryad dataset submission. As a reminder, these')
      expect(mail.body.to_s).to include('changes must be addressed before we can publish your dataset:')
      expect(mail.body.to_s).to include(identifier.identifier)
      expect(mail.body.to_s).to include("Title: \"#{resource.title}\"")
    end

    include_examples 'does not send email for missing resource or user email'
  end
end
