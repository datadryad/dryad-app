describe StashApi::ApiMailer, type: :mailer do

  let(:identifier) { create(:identifier) }
  let(:resource) { create(:resource, identifier: identifier) }
  let(:user) { create(:user) }
  let(:author) { resource.authors.first }
  let(:author2) do
    create(:author, author_first_name: user.first_name, author_last_name: user.last_name, author_email: user.email, author_orcid: user.orcid,
                    resource: resource)
  end
  let(:metadata) { { editLink: '/some/link' } }

  before do
    resource&.reload
    allow(Rails.application.routes.url_helpers).to receive(:root_url).and_return 'https://site.root/'
  end

  describe '#send_submit_request' do
    let(:mail) { described_class.send_submit_request(resource, metadata, author2).deliver_now }

    it 'sends an error report email' do
      expect(mail.to).to eq([author2.author_email])
      expect(mail.subject).to eq("[test] Submit data for \"#{resource.title}\"")
      expect(mail.body.to_s).to include('https://site.root/some/link')
    end

    context 'when user is not present' do
      before { mail.instance_variable_set(:@user, nil) }

      include_examples 'should not send an email'
    end

    context 'when user email is not present' do
      before { allow_any_instance_of(described_class).to receive(:user_email).and_return(nil) }

      include_examples 'should not send an email'
    end
  end
end
