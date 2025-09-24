describe ApplicationMailer, type: :mailer do

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

  describe '#rails_env' do
    it 'returns environment name' do
      expect(described_class.new.send(:rails_env)).to eq('[test] ')
    end

    context 'when in production' do
      before do
        allow(Rails).to receive(:env).and_return('production')
      end

      it 'returns empty string' do
        expect(described_class.new.send(:rails_env)).to be_empty
      end
    end
  end
end
