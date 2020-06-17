require 'rails_helper'

module StashDatacite
  describe Contributor do
    attr_reader :contrib
    before(:each) do
      user = StashEngine::User.create(
        email: 'lmuckenhaupt@example.edu',
        tenant_id: 'dataone'
      )
      resource = StashEngine::Resource.create(user_id: user.id)
      @contrib = Contributor.create(
        resource_id: resource.id,
        contributor_name: 'Elvis Presley',
        contributor_type: 'projectleader'
      )
    end

    describe 'contributor type' do
      describe :contributor_type_friendly do
        it 'returns the Datacite::Mapping value' do
          expect(contrib.contributor_type_friendly).to eq('ProjectLeader')
        end
      end

      describe :contributor_type_mapping_obj do
        it 'returns the Datacite::Mapping enum instance' do
          expect(contrib.contributor_type_mapping_obj).to be(Datacite::Mapping::ContributorType::PROJECT_LEADER)
        end
        it 'maps nil to nil' do
          expect(Contributor.contributor_type_mapping_obj(nil)).to be_nil
        end
        it 'maps Datacite::Mapping values to enum instance' do
          Datacite::Mapping::ContributorType.each do |ct|
            expect(Contributor.contributor_type_mapping_obj(ct.value)).to be(ct)
          end
        end
      end

      describe '#payment_exempted?' do
        before(:each) do
          stub_const('APP_CONFIG', OpenStruct.new(funder_exemptions: %w[Nugget Sprout]))
        end

        it 'is not exempted if it is not a funder' do
          @contrib.update(contributor_name: 'Nugget')
          @contrib.reload
          expect(@contrib.payment_exempted?).to be_falsey
        end

        it 'is not exempted if it does not match' do
          @contrib.update(contributor_type: 'funder')
          @contrib.reload
          expect(@contrib.payment_exempted?).to be_falsey
        end

        it 'is exempted if it matches a funder' do
          @contrib.update(contributor_name: 'Nugget', contributor_type: 'funder')
          @contrib.reload
          expect(@contrib.payment_exempted?).to be_truthy
        end
      end
    end

    describe 'contributor_name_friendly' do
      it 'shows the asterisk when asked' do
        c = Contributor.create(contributor_name: 'Bertelsmann Music Group*')
        expect(c.contributor_name_friendly(show_asterisk: true)).to eq('Bertelsmann Music Group*')
      end
      it 'suppresses the asterisk by default' do
        c = Contributor.create(contributor_name: 'Bertelsmann Music Group*')
        expect(c.contributor_name_friendly).to eq('Bertelsmann Music Group')
      end
    end

    describe 'affiliations' do
      attr_reader :affiliations
      before(:each) do
        @affiliations = ['Graceland', 'RCA', 'RCA Camden', 'Pickwick', 'BMG'].map do |affil|
          Affiliation.create(long_name: affil)
        end
        contrib.affiliation_ids = affiliations.map(&:id)
        contrib.save
        expect(contrib.affiliations.count).to eq(affiliations.size)
      end

      describe '#affiliation_id' do
        it 'returns the ID of the first affiliation' do
          expect(contrib.affiliation_id).to eq(affiliations.first.id)
        end
      end

      describe '#affiliation' do
        it 'returns the first affiliation' do
          expect(contrib.affiliation).to eq(affiliations.first)
        end
      end

      describe '#affiliation_id=' do
        it 'replaces the entire affiliation list' do
          new_affil = Affiliation.create(long_name: 'Metro-Goldwyn-Mayer')
          contrib.affiliation_id = new_affil.id
          expect(contrib.affiliations.count).to eq(1)
          expect(contrib.affiliation).to eq(new_affil)
        end
      end

      describe '#affiliation=' do
        it 'replaces the entire affiliation list' do
          new_affil = Affiliation.create(long_name: 'United Artists')
          contrib.affiliation = new_affil
          expect(contrib.affiliations.count).to eq(1)
          expect(contrib.affiliation_id).to eq(new_affil.id)
        end
      end
    end
  end
end
