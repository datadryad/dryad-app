require 'db_spec_helper'

module StashEngine # TODO: are we testing Author or Affiliation? (Or AuthorPatch?)
  describe Author do
    attr_reader :resource
    attr_reader :author
    before(:each) do
      user = User.create(
        uid: 'lmuckenhaupt-example@example.edu',
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

      describe '#affiliation_filled' do
        it 'returns authors with affiliations' do
          Author.create(resource_id: resource.id, author_first_name: 'Priscilla', author_last_name: 'Presley')
          filled = Author.affiliation_filled.to_a
          # TODO: stop returning n copies of the model for n affiliations
          expect(filled).to be_truthy
        end
      end

      describe '#affiliation_id' do
        it 'returns the ID of the first affiliation' do
          expect(author.affiliation_id).to eq(affiliations.first.id)
        end
      end

      describe '#affiliation' do
        it 'returns the first affiliation' do
          expect(author.affiliation).to eq(affiliations.first)
        end
      end

      describe '#affiliation_id=' do
        it 'replaces the entire affiliation list' do
          new_affil = StashDatacite::Affiliation.create(long_name: 'Metro-Goldwyn-Mayer')
          author.affiliation_id = new_affil.id
          expect(author.affiliations.count).to eq(1)
          expect(author.affiliation).to eq(new_affil)
        end
      end

      describe '#affiliation=' do
        it 'replaces the entire affiliation list' do
          new_affil = StashDatacite::Affiliation.create(long_name: 'United Artists')
          author.affiliation = new_affil
          expect(author.affiliations.count).to eq(1)
          expect(author.affiliation_id).to eq(new_affil.id)
        end
      end
    end

    describe 'ORCIDs' do
      describe '#orcid_id=' do
        it 'sets the ORCID' do
          orcid = '5555-5555-5555-5555'
          author.orcid_id = orcid
          ident_id = author.name_identifier_id
          expect(ident_id).not_to be_nil
          ident = NameIdentifier.find(ident_id)
          expect(ident.name_identifier_scheme).to eq('ORCID')
          expect(ident.name_identifier).to eq(orcid)
        end

        it 'clears the orcid with nil' do
          author.orcid_id = '5555-5555-5555-5555'
          author.orcid_id = nil
          expect(author.name_identifier_id).to be_nil
        end

        it 'clears the orcid with the empty string' do
          author.orcid_id = '5555-5555-5555-5555'
          author.orcid_id = ''
          expect(author.name_identifier_id).to be_nil
        end

        it 'clears the orcid with a blank string' do
          author.orcid_id = '5555-5555-5555-5555'
          author.orcid_id = ' '
          expect(author.name_identifier_id).to be_nil
        end

        it 'doesn\'t clear non-ORCID identifiers' do
          name_ident = NameIdentifier.create(name_identifier_scheme: 'ISNI', name_identifier: '0000-0001-1690-159X')
          author.name_identifier_id = name_ident.id
          author.save
          author.orcid_id = nil
          expect(author.name_identifier_id).to eq(name_ident.id)
        end
      end

      describe 'orcid_id' do
        it 'returns the ORCID' do
          orcid = '5555-5555-5555-5555'
          author.orcid_id = orcid
          expect(author.orcid_id).to eq(orcid)
        end

        it 'returns nil for non-ORCID IDs' do
          name_ident = NameIdentifier.create(name_identifier_scheme: 'ISNI', name_identifier: '0000-0001-1690-159X')
          author.name_identifier_id = name_ident.id
          author.save
          expect(author.orcid_id).to be_nil
        end
      end
    end
  end
end
