require 'db_spec_helper'

module StashEngine # TODO: are we testing Author or Affiliation? (Or AuthorPatch?)
  describe Author do
    attr_reader :resource
    attr_reader :author
    before(:each) do
      user = User.create(
        email: 'lmuckenhaupt@example.edu',
        tenant_id: 'dataone'
      )
      @resource = Resource.create(user_id: user.id)
      @author = Author.create(
        resource_id: resource.id,
        author_first_name: 'Elvis',
        author_last_name: 'Presley'
      )
    end

    describe 'scopes' do
      describe :affiliation_filled do
        xit 'includes affiliations w/short name'
        xit 'includes affiliations w/long name'
        xit 'includes affiliations w/both'
        xit 'excludes affiliations w/neither'
      end
    end

    describe 'emails' do
      before(:each) do
        @auth = Author.new(resource_id: resource.id, author_first_name: 'Jane', author_last_name: 'Doe')
      end
      it 'does not require email' do
        expect(@auth.valid?).to eql(true)
        expect(@auth.errors.empty?).to eql(true)
      end
      it 'validates email format' do
        %w[abcdefg abcdefg@bademail abcdefg@bademail,bademl @bad.eml abcdefgbad.eml].each do |email|
          @auth.author_email = email
          expect(@auth.valid?).to eql(false), "expected '#{email}' to be invalid"
          expect(@auth.errors[:author_email].first).to eql('is invalid')
        end
        @auth.author_email = 'abcdefg@bad.eml'
        expect(@auth.valid?).to eql(true)
        expect(@auth.errors.empty?).to eql(true)
      end
    end

    describe 'affiliations' do
      attr_reader :affiliations
      before(:each) do
        @affiliations = ['Graceland', 'RCA', 'RCA Camden', 'Pickwick', 'BMG'].map do |affil|
          StashDatacite::Affiliation.create(long_name: affil)
        end
        author.affiliation_ids = affiliations.map(&:id)
        author.save
        expect(author.affiliations.count).to eq(affiliations.size)
      end

      describe '#affiliation' do
        it 'returns the first affiliation' do
          expect(author.affiliation).to eq(affiliations.first)
        end
      end

      describe '#affiliation=' do
        it 'replaces the entire affiliation list' do
          new_affil = StashDatacite::Affiliation.create(long_name: 'Metro-Goldwyn-Mayer')
          author.affiliation = new_affil
          expect(author.affiliations.count).to eq(1)
          expect(author.affiliation).to eq(new_affil)
        end
      end

    end

    describe 'ORCIDs' do
      describe '#author_orcid=' do
        it 'sets the ORCID' do
          orcid = '5555-5555-5555-5555'
          author.author_orcid = orcid
          expect(author.author_orcid).to eq(orcid)
        end

        it 'clears the orcid with nil' do
          author.author_orcid = '5555-5555-5555-5555'
          author.author_orcid = nil
        end

        it 'clears the orcid with the empty string' do
          author.author_orcid = '5555-5555-5555-5555'
          author.author_orcid = ''
        end

        it 'clears the orcid with a blank string' do
          author.author_orcid = '5555-5555-5555-5555'
          author.author_orcid = ' '
        end
      end

      describe 'author_orcid' do
        it 'returns the ORCID' do
          orcid = '5555-5555-5555-5555'
          author.author_orcid = orcid
          expect(author.author_orcid).to eq(orcid)
        end
      end
    end
  end
end
