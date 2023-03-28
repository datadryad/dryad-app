require 'rails_helper'

module StashEngine

  RSpec.describe JournalOrganization, type: :model do

    before(:each) do
      @org = build(:journal_organization)
    end

    describe 'journals_sponsored' do
      it 'returns blank when there are none' do
        expect(@org.journals_sponsored).to be_blank
      end

      it 'returns sponsored journals with a direct relationship' do
        journal = create(:journal, sponsor: @org)
        expect(@org.journals_sponsored.size).to eq(1)
        expect(@org.journals_sponsored.first).to eq(journal)
      end
    end

    describe 'journals_sponsored_deep' do
      it 'returns blank when there are none' do
        expect(@org.journals_sponsored_deep).to be_blank
      end

      it 'returns sponsored journals with a direct relationship' do
        journal = create(:journal, sponsor: @org)
        found_journals = @org.journals_sponsored_deep
        expect(found_journals.size).to eq(1)
        expect(found_journals.first).to eq(journal)
      end

      it 'returns sponsored journals with a deep relationship' do
        journal = create(:journal, sponsor: @org)
        suborg = build(:journal_organization)
        suborg.update(parent_org: @org)
        subjournal = create(:journal, sponsor: suborg)
        suborg2 = build(:journal_organization)
        suborg2.update(parent_org: @org)
        subjournal2 = create(:journal, sponsor: suborg2)
        subsuborg = build(:journal_organization)
        subsuborg.update(parent_org: suborg)
        subsubjournal = create(:journal, sponsor: subsuborg)

        found_journals = @org.journals_sponsored_deep
        expect(found_journals.size).to eq(4)
        expect(found_journals).to include(journal)
        expect(found_journals).to include(subjournal)
        expect(found_journals).to include(subjournal2)
        expect(found_journals).to include(subsubjournal)
      end
    end

    describe 'orgs_included' do
      it 'returns blank when there are none' do
        expect(@org.orgs_included).to be_blank
      end

      it 'returns direct sub-orgs' do
        suborg = build(:journal_organization)
        suborg.update(parent_org: @org)
        found_suborgs = @org.orgs_included
        expect(found_suborgs.size).to be(1)
        expect(found_suborgs.first).to eq(suborg)
      end

      it 'returns deeper sub-orgs' do
        suborg = build(:journal_organization)
        suborg.update(parent_org: @org)
        suborg2 = build(:journal_organization)
        suborg2.update(parent_org: @org)
        subsuborg = build(:journal_organization)
        subsuborg.update(parent_org: suborg)

        found_suborgs = @org.orgs_included
        expect(found_suborgs&.size).to be(3)
        expect(found_suborgs).to include(suborg)
        expect(found_suborgs).to include(suborg2)
        expect(found_suborgs).to include(subsuborg)
      end
    end

  end

end
