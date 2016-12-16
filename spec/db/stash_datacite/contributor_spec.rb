require 'db_spec_helper'

module StashDatacite
  describe Contributor do
    attr_reader :contrib
    before(:each) do
      user = StashEngine::User.create(
        uid: 'lmuckenhaupt-example@example.edu',
        email: 'lmuckenhaupt@example.edu',
        tenant_id: 'dataone'
      )
      resource = StashEngine::Resource.create(user_id: user.id)
      @contrib = Contributor.new(
        resource_id: resource.id,
        contributor_name: 'Elvis Presley',
        contributor_type: 'supervisor'
      )
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


# 'contactperson','datacollector','datacurator','datamanager','distributor','editor','funder','hostinginstitution','producer','projectleader','projectmanager','projectmember','registrationagency','registrationauthority','relatedperson','researcher','researchgroup','rightsholder','sponsor','supervisor','workpackageleader','other'
