describe StashEngine::UserMailer, type: :mailer do
  let(:tenant) { create(:tenant_email, authentication: { email_domain: 'domain.com' }.to_json) }
  let(:identifier) { create(:identifier) }
  let(:resource) { create(:resource, identifier: identifier) }
  let(:user) { create(:user) }
  let(:author) { resource.authors.first }
  let(:request_host) { 'stash.example.org' }

  before do
    resource&.reload
    identifier.reload
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
end
