require 'db_spec_helper'

module StashDatacite
  describe Creator do
    attr_reader :resource
    attr_reader :creator
    before(:each) do
      user = StashEngine::User.create(
        uid: 'lmuckenhaupt-example@example.edu',
        email: 'lmuckenhaupt@example.edu',
        tenant_id: 'dataone'
      )
      @resource = StashEngine::Resource.create(user_id: user.id)
      @creator = Creator.create(
        resource_id: resource.id,
        creator_first_name: 'Elvis',
        creator_last_name: 'Presley'
      )
    end

    describe 'scopes' do
    end

    describe 'affiliations' do
      attr_reader :affiliations
      before(:each) do
        @affiliations = ['Graceland', 'RCA', 'RCA Camden', 'Pickwick', 'BMG'].map do |affil|
          Affiliation.create(long_name: affil)
        end
        creator.affiliation_ids = affiliations.map(&:id)
        creator.save
        expect(creator.affiliations.count).to eq(affiliations.size)
      end

      describe '#affiliation_filled' do
        it 'returns creators with affiliations' do
          Creator.create(resource_id: resource.id, creator_first_name: 'Priscilla', creator_last_name: 'Presley')
          filled = Creator.affiliation_filled.to_a
          expect(filled).to contain_exactly(creator)
        end
      end

      describe '#affiliation_id' do
        it 'returns the ID of the first affiliation' do
          expect(creator.affiliation_id).to eq(affiliations.first.id)
        end
      end

      describe '#affiliation' do
        it 'returns the first affiliation' do
          expect(creator.affiliation).to eq(affiliations.first)
        end
      end

      describe '#affiliation_id=' do
        it 'replaces the entire affiliation list' do
          new_affil = Affiliation.create(long_name: 'Metro-Goldwyn-Mayer')
          creator.affiliation_id = new_affil.id
          expect(creator.affiliations.count).to eq(1)
          expect(creator.affiliation).to eq(new_affil)
        end
      end

      describe '#affiliation=' do
        it 'replaces the entire affiliation list' do
          new_affil = Affiliation.create(long_name: 'United Artists')
          creator.affiliation = new_affil
          expect(creator.affiliations.count).to eq(1)
          expect(creator.affiliation_id).to eq(new_affil.id)
        end
      end
    end

    describe 'ORCIDs' do
      describe '#orcid_id=' do
        it 'sets the ORCID' do
          orcid = '5555-5555-5555-5555'
          creator.orcid_id = orcid
          ident_id = creator.name_identifier_id
          expect(ident_id).not_to be_nil
          ident = NameIdentifier.find(ident_id)
          expect(ident.name_identifier_scheme).to eq('ORCID')
          expect(ident.name_identifier).to eq(orcid)
        end

        it 'clears the orcid with nil' do
          creator.orcid_id = '5555-5555-5555-5555'
          creator.orcid_id = nil
          expect(creator.name_identifier_id).to be_nil
        end

        it 'clears the orcid with the empty string' do
          creator.orcid_id = '5555-5555-5555-5555'
          creator.orcid_id = ''
          expect(creator.name_identifier_id).to be_nil
        end

        it 'clears the orcid with a blank string' do
          creator.orcid_id = '5555-5555-5555-5555'
          creator.orcid_id = ' '
          expect(creator.name_identifier_id).to be_nil
        end

        it 'doesn\'t clear non-ORCID identifiers' do
          name_ident = NameIdentifier.create(name_identifier_scheme: 'ISNI', name_identifier: '0000-0001-1690-159X')
          creator.name_identifier_id = name_ident.id
          creator.save
          creator.orcid_id = nil
          expect(creator.name_identifier_id).to eq(name_ident.id)
        end
      end

      describe 'orcid_id' do
        it 'returns the ORCID' do
          orcid = '5555-5555-5555-5555'
          creator.orcid_id = orcid
          expect(creator.orcid_id).to eq(orcid)
        end

        it 'returns nil for non-ORCID IDs' do
          name_ident = NameIdentifier.create(name_identifier_scheme: 'ISNI', name_identifier: '0000-0001-1690-159X')
          creator.name_identifier_id = name_ident.id
          creator.save
          expect(creator.orcid_id).to be_nil
        end
      end
    end
  end
end
