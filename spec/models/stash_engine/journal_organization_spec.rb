require 'rails_helper'

module StashEngine

  RSpec.describe JournalOrganization, type: :model do

    before(:each) do
      @org = build(:journal_organization)
    end

    describe 'journals_sponsored' do
      it 'returns nil when there are none' do
        expect(@org.journals_sponsored).to be_blank
      end

      it 'returns sponsored journals with a direct relationship' do
        user = create(:user)
        journal = create(:journal, sponsor: @org)
        create(:journal_role, journal: nil, journal_organization: @org, user: user, role: 'org_admin')
        expect(@org.journals_sponsored.size).to eq(1)
        expect(@org.journals_sponsored.first).to eq(journal)
      end

    end

  end

end
