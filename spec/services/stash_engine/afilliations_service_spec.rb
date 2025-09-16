describe AuthorsService do
  let(:identifier) { create(:identifier) }
  let(:identifier2) { create(:identifier) }
  let(:resource) { create(:resource, identifier: identifier) }
  let(:resource2) { create(:resource, identifier: identifier2) }
  let!(:author) { create(:author, author_email: 'author@example.com', author_orcid: '', resource: resource2) }

  describe '#initialize' do
    subject { described_class.new(author) }

    it 'sets the main affiliation' do
      expect(subject.author).to eq(author)
    end
  end

  describe '#check_orcid' do
    subject { described_class.new(author).check_orcid }

    context 'when author is blank' do
      let(:author) { nil }

      it 'does not raise errors' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when there are multiple authors' do
      let!(:author1) { create(:author, author_email: 'author@example.com', author_orcid: '') }
      let!(:author2) { create(:author, author_email: 'author@example.com', author_orcid: '1234-1234-1234-1234') }
      let!(:author3) { create(:author, author_email: 'author@example.com', author_orcid: '1234-1234-1234-4321') }

      it 'users first author ORCID' do
        subject
        expect(author.reload.author_orcid).to eq(author2.author_orcid)
      end
    end

    context 'when there are multiple users' do
      let!(:user1) { create(:user, email: 'author@example.com', orcid: nil) }
      let!(:user2) { create(:user, email: 'author@example.com', orcid: '1234-1234-1234-1234') }
      let!(:user3) { create(:user, email: 'author@example.com', orcid: '1234-1234-1234-4321') }

      it 'users first user ORCID' do
        subject
        expect(author.reload.author_orcid).to eq(user2.orcid)
      end
    end

    context 'when there is an user and an author' do
      let!(:author1) { create(:author, author_email: 'author@example.com', author_orcid: '1234-1234-1234-4321') }
      let!(:user1) { create(:user, email: 'author@example.com', orcid: '1234-1234-1234-1234') }

      it 'uses user ORCID' do
        subject
        expect(author.reload.author_orcid).to eq(user1.orcid)
      end
    end
  end

  describe '#fix_missing_orchid' do
    subject { described_class.new.fix_missing_orchid }

    context 'when author in conflicts based on authors info' do
      let!(:author1) { create(:author, author_email: 'author@example.com', author_orcid: '1234-1234-1234-1234', resource: resource) }
      let!(:author2) { create(:author, author_email: 'author@example.com', author_orcid: '1234-1234-1234-4321', resource: resource) }

      it 'does not update the ORCID' do
        subject
        expect(author.reload.author_orcid).to be_nil
      end
    end

    context 'when author in conflicts' do
      context 'based on users info' do
        let!(:user1) { create(:user, email: 'author@example.com', orcid: '1234-1234-1234-1234') }
        let!(:user2) { create(:user, email: 'author@example.com', orcid: '1234-1234-1234-4321') }

        it 'does not update the ORCID' do
          subject
          expect(author.reload.author_orcid).to be_nil
        end
      end

      context 'based on user and author info' do
        let!(:user1) { create(:user, email: 'author@example.com', orcid: '1234-1234-1234-1234') }
        let!(:author2) { create(:author, author_email: 'author@example.com', author_orcid: '1234-1234-1234-4321', resource: resource) }

        it 'does not update the ORCID' do
          subject
          expect(author.reload.author_orcid).to be_nil
        end
      end
    end

    context 'when author is not in conflicts' do
      context 'when ORCID is set on user' do
        let!(:user1) { create(:user, email: 'author@example.com', orcid: '1234-1234-1234-1234') }

        it 'updates the ORCID' do
          subject
          expect(author.reload.author_orcid).to eq('1234-1234-1234-1234')
        end
      end

      context 'when ORCID is set on author' do
        let!(:author1) { create(:author, author_email: 'author@example.com', author_orcid: '1234-1234-1234-4321', resource: resource) }

        it 'updates the ORCID' do
          subject
          expect(author.reload.author_orcid).to eq('1234-1234-1234-4321')
        end
      end
    end
  end
end
